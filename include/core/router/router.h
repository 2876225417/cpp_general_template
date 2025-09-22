

#ifndef ROUTER_HPP
#define ROUTER_HPP


#include <router/table.h>
#include <router/meta.h>
#include <http/connection.h>

namespace qwq::core::router {

/* Route Table */
#define ROUTE_TABLE() \
    (::qwq::core::router::table::RouteTable<::qwq::core::router::meta::HTTPCmpn>::instance())

#define FIND_ROUTE(path) \
    ROUTE_TABLE().find_route(path)

#define SHOW_ROUTES() \
    ROUTE_TABLE().show_routes()

#define IS_ROUTE_TABLE_VALID() \
    ROUTE_TABLE().is_valid()

/* Route Register */
#define ROUTE_WITH_CTX(method, path, ...) \
    do { \
        ::qwq::core::router::meta::HTTPCmpn route{ \
            std::string_view(path), \
            ::qwq::core::router::meta::HTTPMethod::method, \
            [=](::qwq::core::http::connection::HTTPConnection& conn) { __VA_ARGS__ } \
        }; \
        auto res = ROUTE_TABLE().add_route(std::move(route)); \
        (void)res; \
    } while(0)

#define ROUTE_WITH_CTX_LAMBDA(method, path, handler_lambda) \
    do { \
        ::qwq::core::router::meta::HTTPCmpn route{ \
            std::string_view(path), \
            ::qwq::core::router::meta::HTTPMethod::method, \
            handler_lambda \
        }; \
        auto res = ROUTE_TABLE().add_route(std::move(route)); \
        (void)res; \
    } while(0)

#define ROUTE_WITH_CTX_FUNC(method, path, handler_func_obj) \
    do { \
        ::qwq::core::router::meta::HTTPCmpn route{ \
            std::string_view(path), \
            ::qwq::core::router::meta::HTTPMethod::method, \
            handler_func_obj \
        }; \
        auto res = ROUTE_TABLE().add_route(std::move(route)); \
        (void)res; \
    } while (0)

/* Inline Code */
#define GET(path, ...)    ROUTE_WITH_CTX(GET,    path, __VA_ARGS__)
#define POST(path, ...)   ROUTE_WITH_CTX(POST,   path, __VA_ARGS__)
#define PUT(path, ...)    ROUTE_WITH_CTX(PUT,    path, __VA_ARGS__)
#define DELETE(path, ...) ROUTE_WITH_CTX(DELETE, path, __VA_ARGS__)

/* With Lambda */
#define GET_L(path, lambda)    ROUTE_WITH_CTX_LAMBDA(GET, path, lambda)
#define POST_L(path, lambda)   ROUTE_WITH_CTX_LAMBDA(POST, path, lambda)
#define PUT_L(path, lambda)    ROUTE_WITH_CTX_LAMBDA(PUT, path, lambda)
#define DELETE_L(path, lambda) ROUTE_WITH_CTX_LAMBDA(DELETE, path, lambda)

/* With Function Object */
#define GET_F(path, func_obj)    ROUTE_WITH_CTX_FUNC(GET, path, func_obj)
#define POST_F(path, func_obj)   ROUTE_WITH_CTX_FUNC(POST, path, func_obj)
#define PUT_F(path, func_obj)    ROUTE_WITH_CTX_FUNC(PUT, path, func_obj)
#define DELETE_F(path, func_obj) ROUTE_WITH_CTX_FUNC(DELETE, path, func_obj)




} // namespace geecodex::http
#endif // ROUTER_HPP
