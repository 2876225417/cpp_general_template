#ifndef QWQ_CORE_ROUTER_TABLE_H_
#define QWQ_CORE_ROUTER_TABLE_H_


#include <router/trie.h>
#include <memory>
#include <router/meta.h>

#define NO_IMPL false

namespace qwq::core::router::table {
template <typename T>
class RouteTable {
public:
    static RouteTable& instance() {
        static RouteTable instance;
        return instance;
    }
 
    RouteTable(const RouteTable&) = delete;
    RouteTable(RouteTable&&) = delete;
    RouteTable& operator=(const RouteTable&) = delete;
    RouteTable& operator=(RouteTable&&) = delete;
    
    [[nodiscard]] 
    auto add_route(T&& route_data) -> bool
    { return NO_IMPL; }
    
    template <typename... Args>
    [[nodiscard]]
    auto find_route(Args&&...) const -> T
    { return NO_IMPL; }

    [[nodiscard]]
    auto is_trie_valid() const -> bool 
    { return NO_IMPL; }

    auto show_routes() const { }
private:
    RouteTable()
        : ptr_trie_{std::make_unique<trie::Trie<T>>()} {}
    std::unique_ptr<trie::Trie<T>> ptr_trie_;
};

#undef NO_IMPL

template <> 
class RouteTable<meta::HTTPCmpn> {
public:
    static RouteTable& instance() {
        static RouteTable instance;
        return instance;
    }
 
    RouteTable(const RouteTable&) = delete;
    RouteTable(RouteTable&&) = delete;
    RouteTable& operator=(const RouteTable&) = delete;
    RouteTable& operator=(RouteTable&&) = delete;
    
    [[nodiscard]]
    auto add_route(meta::HTTPCmpn&& route_data) {
        if (!is_trie_valid() || route_data.path_.empty())
        { return false; }
        std::cout << route_data << '\n';
       return ptr_trie_->add_route(std::move(route_data)); 
    }

    [[nodiscard]]
    auto add_route(const meta::HTTPCmpn& route_data) {
        auto copy = route_data;
        return add_route(std::move(copy));
    }
     
    [[nodiscard]]
    auto find_route(std::string_view path) const -> trie::MatchResult {
        trie::MatchResult result;
        if (!is_valid() || path.empty()) 
        { return result; }
        result = ptr_trie_->find(path);
        return result;
    }

    [[nodiscard]]
    auto is_valid() const -> bool 
    { return is_trie_valid(); }

    void show_routes() const 
    { ptr_trie_->show_trie(); }

private:
    RouteTable()
        : ptr_trie_{std::make_unique<trie::Trie<meta::HTTPCmpn>>()} { }
    ~RouteTable() = default;
    std::unique_ptr<trie::Trie<meta::HTTPCmpn>> ptr_trie_;

    auto is_trie_valid() const -> bool 
    { return ptr_trie_ != nullptr; }
};
} // NAMESPACE QWQ::CORE::ROUTER::TABLE
#endif // QWQ_CORE_ROUTER_TABLE_H_
