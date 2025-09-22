#ifndef QWQ_CORE_ROUTER_TRIE_H_
#define QWQ_CORE_ROUTER_TRIE_H_

#include <string>
#include <map>
#include <memory>
#include <type_traits>
#include <vector>
#include <iostream>
#include <string>
#include <router/meta.h>

namespace qwq::core::router::table::trie {
// Helper function forward declaration
std::vector<std::string_view> split_path(std::string_view path);

template <typename T>
struct Node {
    /** Node meta info
     *  1. children       a children with the same structure as itself
     *  2. param_child    a children with parameterized data like api/:id  
     *  3. wildcard_child a children with wildcard data like api/file/-image
     *  4. any types of data like a callback function 
     */
    
    /** !!!IMPORTANT!!!
     *  Use std::string to store string value rather than std::string_view
     *  std::string_view may cause memory issues
     *  std::string_view fits in viewing or processing string
     *  TODO(ppqwqqq): 
     *      1. fix issue: 
     *          std::string_view not fully compatible with auto split_path()
     *      2. optimize member type 
     *          replace T (type of data_) with std::unique_ptr<T>
     */
    std::map<std::string, std::unique_ptr<Node<T>>> children_;

    std::unique_ptr<Node<T>> param_child_;
    std::string param_name_;

    std::unique_ptr<Node<T>> wildcard_child_;
    std::string wildcard_name_;
    
    T data_;
    
    [[nodiscard]]
    auto is_valid() const -> bool 
    { return has_children() || has_data(); }
private:
    auto has_children() const -> bool {
        bool has__children =  !children_.empty()
                          || (param_child_ != nullptr)
                          || (wildcard_child_ != nullptr);
        return has__children;
    }

    bool has_data() const
    { return has_data_impl(data_); }

    // Check whether T is able convertible to bool
    //  implement a operator T() overload to fix relative issues
    //  AKA: type conversion overload 
    auto has_data_impl(const T& data) const -> bool {
        if constexpr (std::is_convertible_v<T, bool>) 
        { return static_cast<bool>(data); }
        else 
        { return true; }
    } 
};

template <typename T>
class Trie {
public:
    using NodeType = Node<T>;
    struct MatchResult{
        T* matched_data_;
        std::map<std::string, std::string> params_;
        
        MatchResult(): matched_data_{nullptr} { }
        
        MatchResult(const MatchResult& other): 
            matched_data_{other.matched_data_}, 
            params_{other.params_} {}

        MatchResult(MatchResult&& other) noexcept:
            matched_data_{std::exchange(other.matched_data_, nullptr)},
            params_{std::move(other.params_)} {}

        MatchResult& operator=(const MatchResult& other) {
            if (this != &other) {
                matched_data_ = other.matched_data_;
                params_ = other.params_;
            }
            return *this;
        }
        
        MatchResult& operator=(MatchResult&& other) noexcept {
            if (this != &other) {
                matched_data_ = std::exchange(other.matched_data_, nullptr);
                params_ = std::move(other.params_);
            }
            return *this;
        }

        friend bool operator==(const MatchResult& lhs, const MatchResult& rhs) {
            return lhs.matched_data_ == rhs.matched_data_ && lhs.params_ == rhs.params_;
        }  

        friend bool operator!=(const MatchResult& lhs, const MatchResult& rhs) 
        { return !(lhs == rhs); }
    };
             
    explicit Trie() = default;
     
    [[nodiscard]] 
    auto find(std::string_view path) const -> MatchResult;
    [[nodiscard]]
    auto add_route(std::string_view path, const T& data) -> bool;
    auto add_route(T&& data, const std::string_view path = "") -> bool;
    void show_trie(const Node<T>* current = nullptr, size_t max_depth = 10) ;
private:
    Node<T> root_; 
    auto add_recursive( Node<T>* current
                      , const std::vector<std::string_view>& segments
                      , size_t depth, const T& data) -> bool;
    auto find_recursive( const Node<T>* current
                       , const std::vector<std::string_view>& segments
                       , size_t depth, MatchResult& result
                       ) const -> bool;
    void show_recursive( const Node<T>* current
                       , size_t depth
                       , size_t max_depth);
};

using MatchResult = Trie<meta::HTTPCmpn>::MatchResult;

template <typename T>
auto Trie<T>::find(std::string_view path) const -> MatchResult {
    MatchResult result; 
    auto segments = split_path(path);
    find_recursive(&root_, segments, 0, result);
    return result;
}

template <typename T>
auto Trie<T>::add_route(std::string_view path, const T& data) -> bool {
    auto segments = split_path(path);
    return add_recursive(&root_, segments, 0, data);
}

template <typename T>
auto Trie<T>::add_route(T&& data, const std::string_view path) -> bool {
    std::string_view target_path = "";

    if constexpr (std::is_same_v<meta::HTTPCmpn, T>) 
    { target_path = data.path_; }
    else 
    { target_path = path; }

    auto segments = split_path(target_path);
    return add_recursive(&root_, segments, 0, data);
}

template <typename T>
void Trie<T>::show_trie(const Node<T>* current, size_t max_depth) {
    if (current == nullptr) 
    { current = &root_; }
    std::cout << "===Trie Structure===\n";
    show_recursive(current, 0, 10);
    std::cout << "====================\n";
}

template <typename T>
auto Trie<T>::add_recursive( Node<T>* current
                           , const std::vector<std::string_view>& segments
                           , size_t depth, const T& data) -> bool {
    if (!current || depth > segments.size())
    { return false; }

    if (segments.size() == depth) {
        current->data_ = data;
        return true;
    }

    const auto& segment = segments[depth];

    if (segment.front() == ':') {
        if (segment.length() <= 1) 
        { return false; }

        if (!current->param_child_)
        { current->param_child_ = std::make_unique<Node<T>>(); }

        current->param_name_ = std::string(segment.substr(1));
        return add_recursive(current->param_child_.get(), segments, depth + 1, data);
    } else if (segment.front() == '*') {
        if (segment.length() <= 1)
        { return false; }

        if (!current->wildcard_child_) {
            current->wildcard_child_ = std::make_unique<Node<T>>();
        }
        current->wildcard_name_ = std::string(segment.substr(1));
        current->wildcard_child_->data_ = data;
        
        return true;
    } else {
        try {
            auto& child = current->children_[std::string(segment)];
            if (!child) child = std::make_unique<Node<T>>();
            return add_recursive(child.get(), segments, depth + 1, data);
        } catch (const std::exception&) {
            return false;
        }
    }
}

template <typename T>
auto Trie<T>::find_recursive( const Node<T>* current
                            , const std::vector<std::string_view>& segments
                            , size_t depth, MatchResult& result
                            ) const -> bool {
    if (!current) 
    { return false; }

    if (depth == segments.size()) {
        if constexpr (std::is_constructible_v<T>) {
            if (static_cast<bool>(current->data_)) { 
                result.matched_data_ = const_cast<T*>(&current->data_);
                return true;
            }
        } else { /* For default non-constructible type */
            if (&current->data_) {
                result.matched_data_ = const_cast<T*>(&current->data_);
                return true;
            }
        }

        if (current->wildcard_child_ && static_cast<bool>(current->wildcard_child_->data_)) {
            result.params_[current->param_name_] = "";
            result.matched_data_ = const_cast<T*>(&current->wildcard_child_->data_);
            return true;
        }
        return false;
    }

    if (segments.empty() || depth >= segments.size()) 
    { return false; }
 
    const auto& segment = segments[depth];

    if (auto it = current->children_.find(std::string(segment)); it != current->children_.end()) {
        if (find_recursive(it->second.get(), segments, depth + 1, result)) 
            return true;
    }

    if (current->param_child_) {
        result.params_[current->param_child_->param_name_] = std::string(segment);
        if (find_recursive(current->param_child_.get(), segments, depth + 1, result))
            return true;
        result.params_.erase(current->param_child_->param_name_);
    }

    if (current->wildcard_child_) {
        std::string remaining;
        for (size_t i = depth; i < segments.size(); ++i) {
            if (!remaining.empty()) remaining = "/";
            remaining += segments[i];
        }
        result.params_[current->wildcard_child_->wildcard_name_] = remaining;
        result.matched_data_ = const_cast<T*>(&current->wildcard_child_->data_);
        return true;
    }
    return false;
}

template <typename T>
void Trie<T>::show_recursive( const Node<T>* current
                            , size_t depth, size_t max_depth) {
    if (current == nullptr || depth > max_depth) return;
    
    std::string indent(depth * 2, ' ');
    std::cout << indent << "Node [depth=" << depth << "]";

    std::cout << " (valid: " << (current->is_valid() ? "true" : "false") << ")";

    if (!current->param_name_.empty()) 
    { std::cout << "[param: " << current->param_name_ << "]"; }
    if (!current->wildcard_name_.empty())
    { std::cout << "[wildcard: " << current->wildcard_child_ << "]"; }

    std::cout << '\n';

    if (current->param_child_ && depth < max_depth) {
        std::cout << indent << "   |-- PARAM_CHILD: " << current->param_name_ << '\n';
        show_recursive(current->param_child_.get(), depth + 1, max_depth);
    }

    if (current->wildcard_child_ && depth < max_depth) {
        std::cout << indent << "   |-- WILDCARD_CHILD: " << current->wildcard_name_ << '\n';
        show_recursive(current->wildcard_child_.get(), depth + 1, max_depth);
    }

    for (const auto& pair: current->children_) {
        if (depth < max_depth) {
            std::cout << indent << "   |-- CHILD: " << pair.first << '\n';
#ifdef DEBUG
            const auto* child_node = pair.second.get();
            if (child_node->is_valid() && child_node->data_) {
                if constexpr (std::is_same_v<T, meta::HTTPCmpn>)
                { std::cout << indent << "   Method: " << static_cast<int>(child_node->data_.method_type_) << '\n'; }
            }
#endif // DEBUG
            show_recursive(pair.second.get(), depth + 1, max_depth);
        }
    }
}

} // NAMESPACE QWQ::CORE::ROUTER::TABLE

#endif // QWQ_CORE_ROUTER_TRIE_H_
