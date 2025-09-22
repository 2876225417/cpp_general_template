#ifndef QWQ_CORE_ROUTER_META_H_
#define QWQ_CORE_ROUTER_META_H_


// #include <boost/beast/http/verb.hpp>
#include <cstdint>
#include <functional>
#include <string_view>
#include <iostream>
#include <utility>

#include <http/connection.h>

namespace qwq::core::router::meta {

enum class HTTPMethod: std::int8_t {
    UNKNOWN,
    GET,
    POST,
    PUT,
    DELETE,
    PATCH,
};

struct HTTPCmpn {
    using HTTPHandler_t = std::function<void(http::connection::HTTPConnection&)>;
    using HTTPPath_t    = std::string_view;
    using HTTPMethod_t  = meta::HTTPMethod;
    using HTTPHandler   = HTTPHandler_t;
    using HTTPPath      = HTTPPath_t;
    using HTTPMethod    = HTTPMethod_t;

    HTTPPath         path_;
    HTTPMethod       method_type_;
    HTTPHandler      handler_;

    constexpr explicit operator bool() const noexcept {
        auto res = !path_.empty() && handler_ != nullptr;
        
        // if (res) { std::cout << "Valid adding data\n"; }
        // else { 
        //     std::cout << "Invalid adding data\n"; 
        //     std::cout << "Added path: " << path_;
        //
        // }
    
        return res;
    }
    
    friend constexpr bool operator==(const HTTPCmpn& lhs, const HTTPCmpn& rhs) 
    { return lhs.path_ == rhs.path_ || lhs.method_type_ == rhs.method_type_; }

    friend constexpr bool operator!=(const HTTPCmpn& lhs, const HTTPCmpn& rhs) 
    { return !(lhs == rhs); }
   
    friend std::ostream& operator<<(std::ostream& os, const HTTPCmpn& obj) {
        if (!obj) 
        { os << "Invalid HTTPCmpn obj" << '\n'; }
        else 
        { os << "==== HTTPCmpn ====" << '\n'; 
          os << "path: " << obj.path_ << '\n';
          os << "method_type: " << static_cast<int>(obj.method_type_) << '\n';
          os << "handler: " << (obj.handler_ == nullptr ? "null" : "not null") << '\n';
        }
        return os;
    }

    /** TODO(ppqwqqq): Constructor to adjust
     *      Delegating constructor:
     *          assemble the prior former members(request_path, request_type)
     *      Unify the accept type of handler_ with std::optional
     *          AKA, std::optional<HTTPMethod> handler_;
     */

    HTTPCmpn()
        : path_{""}
        , method_type_{HTTPMethod::UNKNOWN}
        , handler_{nullptr} 
        { }

    HTTPCmpn( std::string_view request_path
            , meta::HTTPMethod request_type
            , HTTPHandler handler
            ):path_{request_path}
            , method_type_{request_type}
            , handler_{std::move(handler)} 
            { /* Function Object Support */ }

    template <typename Callable>
    HTTPCmpn( std::string_view request_path 
            , meta::HTTPMethod request_type 
            , Callable&& handler
            /* If not support requires keyword, use this instead */
             /* std::enable_if_t<std::is_invocable_v<Callable, http::connection::HTTPConnection&>, int> = 0 */
             ) requires std::is_invocable_v<Callable, http::connection::HTTPConnection&>
            : path_{request_path} 
            , method_type_{request_type}
            , handler_(std::forward<Callable>(handler))
            { /* Lambda Support */ }

    void execute(http::connection::HTTPConnection& conn) const {
        // std::cout << "Try to execute." << '\n';
        if (handler_) 
        { handler_(conn); }
    }
};


// [[nodiscard]] 
// HTTPMethod to_method(boost::beast::http::verb method) {
//     switch (method) {
//         case boost::beast::http::verb::get:     return HTTPMethod::GET;
//         case boost::beast::http::verb::post:    return HTTPMethod::POST;
//         case boost::beast::http::verb::put:     return HTTPMethod::PUT;
//         case boost::beast::http::verb::delete_: return HTTPMethod::DELETE;
//         default:                                return HTTPMethod::UNKNOWN;
//     }
// }

[[nodiscard]]
inline const char* to_string(HTTPMethod method) {
    switch (method) {
        case HTTPMethod::GET:     return "GET";
        case HTTPMethod::POST:    return "POST";
        case HTTPMethod::PUT:     return "PUT";
        case HTTPMethod::DELETE:  return "DELETE";
        case HTTPMethod::UNKNOWN: return "UNKNOWN";
        default:                  return "UNKNOWN METHOD";
    }
}



} // NAMESPACE QWQ::CORE::ROUTER::META

#endif // QWQ_CORE_ROUTER_META_H_
