#ifndef QWQ_CORE_HTTP_CONNECTION_H_
#define QWQ_CORE_HTTP_CONNECTION_H_


#include <boost/asio/any_io_executor.hpp>
#include <boost/asio/error.hpp>
#include <boost/beast/core/bind_handler.hpp>
#include <boost/beast/core/error.hpp>
#include <boost/beast/core/flat_buffer.hpp>
#include <boost/beast/core/stream_traits.hpp>
#include <boost/beast/core/tcp_stream.hpp>
#include <boost/beast/http.hpp>
#include <boost/beast/http/field.hpp>
#include <boost/beast/http/file_body_fwd.hpp>
#include <boost/beast/http/message_fwd.hpp>
#include <boost/beast/http/status.hpp>
#include <boost/beast/http/string_body_fwd.hpp>
#include <boost/beast/http/verb.hpp>
#include <boost/beast/http/write.hpp>
#include <boost/beast/ssl/ssl_stream.hpp>
#include <boost/core/ignore_unused.hpp>
#include <boost/mp11/set.hpp>
#include <boost/system/detail/errc.hpp>
#include <boost/beast/ssl.hpp>
#include <boost/asio/ssl/error.hpp>
#include <boost/asio/ssl/context.hpp>
#include <boost/asio/ssl/stream.hpp>

#include <map>
#include <memory>
#include <string>
#include <string_view>
#include <sys/socket.h>
#include <iostream>

namespace qwq::core::http::connection {

namespace net = boost::asio;

namespace beast = boost::beast;
namespace http = boost::beast::http;
using tcp = net::ip::tcp;



struct ConnectionInfo {
    using InfoCont_t = std::string_view;
    InfoCont_t target;
    InfoCont_t method;
    InfoCont_t http_version;
    InfoCont_t keep_alive;
    
    using header_t = struct Header {
        
    };

    ConnectionInfo( InfoCont_t target_
                  , InfoCont_t method_
                  , auto http_version_
                  , bool keep_alive_
                  ): target{target_}
                   , method{method_}
                   , http_version{static_cast<int>(http_version_) == 10 ? "1.0" : "1.1"}
                   , keep_alive{keep_alive_ ? "true" : "false"} { }
    
    explicit ConnectionInfo(const http::request<boost::beast::http::string_body>& request)
        : target{request.target().data(), request.target().size()}
        , method{request.method_string()}
        , http_version{static_cast<int>(request.version()) == 10 ? "1.0" : "1.1"}
        , keep_alive{request.keep_alive() ? "true" : "false"} { }
    
    /* Formatted output */
    friend std::ostream& operator<<(std::ostream& os, const ConnectionInfo& obj) {
        os << "Target:       " << obj.target       << '\n'
           << "Method:       " << obj.method       << '\n'
           << "HTTP Version: " << obj.http_version << '\n'
           << "Keep Alive:   " << obj.keep_alive   << '\n';
        return os;
    }
};



class HTTPConnection: public std::enable_shared_from_this<HTTPConnection> {
public:     
    explicit HTTPConnection(tcp::socket&&);
    
    void start();

    tcp::socket& socket();
    http::request<http::string_body>& request();
    http::response<http::string_body>& response(); 
    [[nodiscard]] bool response_sent() const;

    void send(http::response<http::string_body>&& response);
    void send(http::response<http::file_body>&& response);
    
    template <class BodyType>
    void send_response_impl(http::response<BodyType>&& response_to_send, const char* response_description);
    
    void read_request();
    void process_request();
    void write_response(); 
private: 
    tcp::socket                         _socket;
    beast::flat_buffer                  _buffer;
    http::request<http::string_body>    _request;
    http::response<http::string_body>   _response;
    bool                                _response_sent;
    std::map<std::string, std::string>  _path_params;

    using HTTPStatus = http::status;

    auto set_http_response_result( HTTPStatus status
                                 , const std::string& rsp_msg) -> bool{
        _response.set(http::field::content_type, "application/json");
        switch (status) {
            case http::status::ok: { 
                _response.result(http::status::ok);
                _response.body() = rsp_msg.empty() ? R"({"message", "Process request successfully."})" : " ";
                return true;
            }
            case http::status::internal_server_error: { 
            
            }

            default: {
                    return false;
                }
        }

    }
    
    


};

}   // NAMESPACE QWQ::CORE::HTTP::CONNECTION
#endif // QWQ_CORE_HTTP_CONNECTION_H_
