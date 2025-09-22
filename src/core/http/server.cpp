#include <http/server.h>

namespace qwq::core::http::server {


HTTPServer::HTTPServer( net::io_context& io_ctx
                      , tcp::endpoint endpoint
                      ):io_ctx_{io_ctx}
                      , acceptor_(io_ctx) {
    beast::error_code ec;
                
    acceptor_.open(endpoint.protocol(), ec);
    if (ec) { fail(ec, "open"); return; }

    acceptor_.set_option(net::socket_base::reuse_address(true), ec);
    if (ec) { fail(ec, "set_option"); return; }

    acceptor_.bind(endpoint, ec);
    if (ec) { fail(ec, "bind"); return; }

    acceptor_.listen(net::socket_base::max_listen_connections, ec);
    if (ec) { fail(ec, "listen"); return; } 
}

void HTTPServer::run()
{ do_accept(); }


void HTTPServer::do_accept() {
    auto async_handler = [this](beast::error_code ec, tcp::socket socket) {
        if (!ec) std::make_shared<HTTPConnection>(std::move(socket))->start();
        do_accept();
    };
    acceptor_.async_accept(async_handler);
}

void HTTPServer::fail(beast::error_code ec, const char* what)     
{ std::cerr << what << ": " << ec.message() << "\n"; }

} // NAMESPACE QWQ::CORE::HTTP::SERVER






