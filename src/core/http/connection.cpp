
#include "router/meta.h"
#include "router/table.h"
#include "router/trie.h"
#include <boost/beast/core/error.hpp>
#include <boost/beast/http/file_body_fwd.hpp>
#include <boost/beast/http/message_fwd.hpp>
#include <boost/beast/http/status.hpp>
#include <boost/beast/http/string_body_fwd.hpp>
#include <http/connection.h>
#include <router/router.h>

namespace qwq::core::http::connection {

HTTPConnection::HTTPConnection(tcp::socket&& socket)
    : _socket{std::move(socket)}
    , _response_sent{false}
    , _buffer{8192} { }

void HTTPConnection::start() {
    try { 
        read_request();
    } catch (const std::exception& e) {
        std::cerr << "Exception in start(): " << e.what() << std::endl;
    } catch (...) {
        std::cerr << "Unknown exception in start()" << std::endl;
    }
}

tcp::socket& HTTPConnection::socket() 
{ return this->_socket; }

http::request<http::string_body>& HTTPConnection::request() 
{ return this->_request; }

http::response<http::string_body>& HTTPConnection::response() 
{ return this->_response; }

bool HTTPConnection::response_sent() const 
{ return this->_response_sent; }

void HTTPConnection::send(http::response<http::string_body>&& response) 
{ return this->send_response_impl(std::move(response), "string_body"); }

void HTTPConnection::send(http::response<http::file_body>&& response) 
{ return this->send_response_impl(std::move(response), "file_body"); }

void HTTPConnection::read_request() {
    auto self = shared_from_this();
    
    auto async_read_handler = [self](beast::error_code ec, std::size_t bytes_transferred) {
        boost::ignore_unused(bytes_transferred);
        try {
            if (!ec) 
            { self->process_request(); }
            else 
            { std::cerr << "Error reading request :" << ec.message() << "\n"; }    
        } catch (const std::exception& e) {
            std::cerr << "Exception in read_request completion handler: " << e.what() << '\n';
        } catch (...) {
            std::cerr << "Unknown exception in read_request completion handler" << '\n';
        }
    };

    http::async_read(_socket, _buffer, _request, async_read_handler); 
}

void HTTPConnection::process_request() {
    try {
        /* Unified response info */
        _response.version(_request.version());
        _response.keep_alive(false);
        _response.set(http::field::server, "Queue Web Quest");
        
        auto request_info = ConnectionInfo{_request};
        std::cout << request_info << '\n';
         
        auto& table = router::table::RouteTable<router::meta::HTTPCmpn>::instance();
        
        std::cout << "Target path: " << request_info.target << '\n';
        auto target_route_node = table.find_route(request_info.target);   
        
        if (target_route_node.matched_data_) {
            try {
                target_route_node.matched_data_->execute(*this);
                
                if (!_response_sent) {
                    _response.result(http::status::ok);
                    _response.set(http::field::content_type, "application/json");
                    if (_response.body().empty()) 
                    { _response.body() = R"({"message": "Process request susccessfully."})"; }
                }
            } catch (const std::exception& e) {

            } 
        } 

        if (!_response_sent) write_response();
    } catch (const std::exception& e) {
        std::cerr << "Exception in process_request: " << e.what() << std::endl;
        try {
            if (!_response_sent) {
                _response.result(http::status::internal_server_error);
                _response.set(http::field::content_type, "application/json");
                _response.body() = R"({"error": "Internal server error"})";
                write_response();
            }
        } catch (...) {
            std::cerr << "Failed to send error response" << std::endl;
        }
    } catch (...) {
        std::cerr << "Unknown exception in process_request" << std::endl;
        try {
            if (!_response_sent) {
                _response.result(http::status::internal_server_error);
                _response.set(http::field::content_type, "application/json");
                _response.body() = R"({"error": "Unknown internal error"})"; 
                write_response();
            }
        } catch (...) {
            std::cerr << "Failed to send errror response";
        }
    }
}

void HTTPConnection::write_response() {
    try {
        auto self = shared_from_this();    
        _response.content_length(_response.body().size());
        _response_sent = true;
         
        auto async_write_handler = [self] ( beast::error_code ec , std::size_t ) {
            try {  
                if (ec) 
                { std::cerr << "Error writing response: " << ec.message() << "\n"; }
                beast::error_code shutdown_ec;
                self->_socket.shutdown(tcp::socket::shutdown_send, shutdown_ec);
                if (shutdown_ec && shutdown_ec != beast::errc::not_connected)
                { std::cerr << "Error shutting down socket: " << shutdown_ec.message() << '\n'; }
            } catch (const std::exception& e) {
                std::cerr << "Exception in write_response completion handler: " << e.what() << '\n';
            } catch (...) {
                std::cerr << "Unknown exception in write_response completion handler" << '\n';
            }
        };

        http::async_write( _socket, _response, async_write_handler); 
    } catch (const std::exception& e) {
        std::cerr << "Exception in write_response: " << e.what() << '\n';
    } catch (...) {
        std::cerr << "Unknown exception in write_response" << '\n';
    }
}

template <class BodyType>
void HTTPConnection::send_response_impl(http::response<BodyType>&& response_to_send, const char* response_description) {
    if (_response_sent) {
            std::cerr << "Error: Attempted to send response when one was already sent (" 
                      << response_description << ")" << std::endl;
            return;
        }

        try {
            auto shared_response = std::make_shared<http::response<BodyType>>(std::move(response_to_send));
            auto self = shared_from_this();
            _response_sent = true;

            shared_response->prepare_payload();
            
            std::cout << "Starting " << response_description << " transfer. Size: "
                      << shared_response->payload_size().value_or(0) / (1024.f * 1024.f)
                      << " MB" << std::endl;
        
            http::async_write(_socket, *shared_response, [self, shared_response, response_description_str = std::string(response_description)](beast::error_code ec, std::size_t bytes_transferred) {
                try {
                    if (ec) std::cerr << "Error writing response: " << ec.message() << '\n';
                    else std::cout // << response_description_str << " response sent successfully ("
                                   << bytes_transferred / (1024.f * 1024.f)
                                   << " MB)" << std::endl;

                    beast::error_code shutdown_ec;
                    self->_socket.shutdown(tcp::socket::shutdown_send, shutdown_ec);
                    if (shutdown_ec && shutdown_ec != beast::errc::not_connected) 
                        std::cerr << "Error shutting down socket send: " << shutdown_ec.message() << '\n';
                    else if (!shutdown_ec) { /* Optional: Success Response */ }
                } catch (const std::exception& e) {
                    // std::cerr << "Exception in " << response_description_str << " send completion handler: " << e.what() << '\n';
                } catch (...) {
                    std::cerr << "Unknown exception in " << response_description_str << " send completion handler" << '\n';
                }
            });
        } catch (const std::exception& e) {
            std::cerr << "Exception setting up send(" << response_description << "):" << e.what() << '\n';
        } catch (...) {
            std::cerr << "Unknown exception setting up send(" << response_description << ")" << '\n';
        }

}

} // NAMESPACE QWQ::CORE::HTTP::CONNECTION
