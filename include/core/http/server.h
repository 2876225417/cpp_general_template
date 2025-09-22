#ifndef QWQ_CORE_HTTP_SERVER
#define QWQ_CORE_HTTP_SERVER

#include <boost/asio/io_context.hpp>
#include <boost/asio/socket_base.hpp>
#include <boost/beast/core/error.hpp>
#include <http/connection.h>
#include <memory>
#include <iostream>

namespace qwq::core::http::server {

using namespace connection;

struct Config {

};

class HTTPServer {
public: 
    HTTPServer(net::io_context& io_ctx, tcp::endpoint endpoint);
    void run(); 
private:
    net::io_context&    io_ctx_;
    tcp::acceptor       acceptor_;

    void do_accept(); 
    void fail(beast::error_code ec, const char* what); 
};
}   // NAMESPACE GEECODEX
#endif // QWQ_CORE_HTTP_SERVER
