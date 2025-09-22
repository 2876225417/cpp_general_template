

#include "router/meta.h"
#include <functional>
#include <router/table.h>
#include <router/trie.h>
using namespace qwq::core::router::table::trie;
using namespace qwq::core::router;
#include <iostream>

void test_callback(::qwq::core::http::connection::HTTPConnection& conn) {
    std::cout << "Func obj" << '\n';
}
// int main() {
//     std::cout << "=== Testing RouteTable ===" << std::endl;
//
//     auto& route_table = table::RouteTable<meta::HTTPCmpn>::instance();
//
//     // 创建路由
//     meta::HTTPCmpn route1{"/api/test", meta::HTTPMethod::GET,
//         []() { std::cout << "Test route executed!" << std::endl; }};
//
//     meta::HTTPCmpn route2{"/api/user/info", meta::HTTPMethod::GET,
//         []() { std::cout << "User info route executed!" << std::endl; }};
//
//     // 添加路由
//     bool result1 = route_table.add_route(route1);
//     bool result2 = route_table.add_route(route2);
//
//     std::cout << "Add results: " << result1 << ", " << result2 << std::endl;
//
//     route_table.show_routes();
//
//     // 测试查找
//     std::cout << "\n=== Testing RouteTable Find ===" << std::endl;
//     auto find_result1 = route_table.find_route("/api/test");
//     auto find_result2 = route_table.find_route("/api/user/info");
//
//     // 执行找到的路由
//     if (find_result1.matched_data_) {
//         std::cout << "Found /api/test, executing..." << std::endl;
//         find_result1.matched_data_->execute();
//     } else {
//         std::cout << "/api/test not found" << std::endl;
//     }
//
//     if (find_result2.matched_data_) {
//         std::cout << "Found /api/user/info, executing..." << std::endl;
//         find_result2.matched_data_->execute();
//     } else {
//         std::cout << "/api/user/info not found" << std::endl;
//     }
//
//     std::cout << "RouteTable test completed!" << std::endl;
//     return 0;
// }

#include <http/connection.h>
#include <http/server.h>
#include <router/router.h>

int main(int argc, char *argv[]) {

  using namespace qwq::core::http::connection;
  using namespace qwq::core::http::server;

    GET("/api/v1/user/info", { std::cout << "This is a user info..." << '\n'; });

    GET_F("/api/v1/user/test", test_callback);

  try {
    auto const address =
        qwq::core::http::connection::net::ip::make_address(argv[1]);
    unsigned short port = static_cast<unsigned short>(std::atoi(argv[2]));

    std::cout << "address: " << address << '\n';
    std::cout << "port: " << port << '\n';

    net::io_context ioc{2}; // Concurrenct Hint

    HTTPServer server{ioc, {address, port}};

    server.run();
    ioc.run();

  } catch (const std::exception &e) {

    return EXIT_FAILURE;
  }

  return EXIT_SUCCESS;
}

/*  Route Test
    GET("/api/users", {
        std::cout << "Hello /api/users..." << '\n';
        std::cout << conn.request().method() << '\n';
        auto target = std::string_view(conn.request().target().data(),
   conn.request().target().size()); std::cout << "Target path: " << target <<
   '\n';
    });


    GET("/api/users/info", {
        std::cout << "Hello /api/users..." << '\n';
    });

        GET("/api/users/info/name", {
        std::cout << "Hello /api/users..." << '\n';
    });

    POST("/api/file/uplaod", {

    });


    DELETE("/api/file/delete", {

    });


    PUT("/api/file/upload/1", {

    });

    SHOW_ROUTES();
*/
