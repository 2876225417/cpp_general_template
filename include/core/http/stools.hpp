#ifndef QWQ_CORE_HTTP_SENDING_TOOLS_HPP_
#define QWQ_CORE_HTTP_SENDING_TOOLS_HPP_

#include <boost/beast/http.hpp>
#include <http/connection.h>

namespace qwq::core::http::connection::tools {

// using namespace qwq::core::http::connection;


template <typename BodyType>
void send_response( http::response<BodyType>&& response_to_send
                  , const char* response_description) {
        if (m_response_sent) {
            std::cerr << "Error: Attempted to send response when one was already sent (" 
                      << response_description << ")" << std::endl;
            return;
        }

        try {
            auto shared_response = std::make_shared<http::response<BodyType>>(std::move(response_to_send));
            auto self = shared_from_this();
            m_response_sent = true;

            shared_response->prepare_payload();
            
            std::cout << "Starting " << response_description << " transfer. Size: "
                      << shared_response->payload_size().value_or(0) / (1024.f * 1024.f)
                      << " MB" << std::endl;
        
            http::async_write(m_socket, *shared_response, [self, shared_response, response_description_str = std::string(response_description)](beast::error_code ec, std::size_t bytes_transferred) {
                try {
                    if (ec) std::cerr << "Error writing " << response_description_str << " response: " << ec.message() << '\n';
                    else std::cout << response_description_str << " response sent successfully ("
                                   << bytes_transferred / (1024.f * 1024.f)
                                   << " MB)" << std::endl;

                    beast::error_code shutdown_ec;
                    self->m_socket.shutdown(tcp::socket::shutdown_send, shutdown_ec);
                    if (shutdown_ec && shutdown_ec != beast::errc::not_connected) 
                        std::cerr << "Error shutting down socket send: " << shutdown_ec.message() << '\n';
                    else if (!shutdown_ec) { /* Optional: Success Response */ }
                } catch (const std::exception& e) {
                    std::cerr << "Exception in " << response_description_str << " send completion handler: " << e.what() << '\n';
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




} // NAMESPACE QWQ::CORE::HTTP::CONNECTION::TOOLS
#endif // QWQ_CORE_HTTP_SENDING_TOOLS_HPP_
