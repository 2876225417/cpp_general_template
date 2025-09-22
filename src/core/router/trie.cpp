#include <router/trie.h>

namespace qwq::core::router::table::trie {

std::vector<std::string_view> split_path(std::string_view path) {
    std::vector<std::string_view> segments;
    if (path.empty() || path == "/") return segments;
    
    size_t start      = (path.front() == '/') ? 1 : 0;
    size_t end_adjust = (path.length() > 1 && path.back() == '/') ? 1 : 0;
    size_t path_len   = path.length() - end_adjust;
    size_t end        = start;

    while (start < path_len) {
        end = path.find('/', start);
        if (end == std::string_view::npos || end >= path_len) {
            segments.push_back(path.substr(start, path_len - start));
            break;
        }
        segments.push_back(path.substr(start, end - start));
        start = end + 1;
    }
    return segments;
}

} // NAMESPACE QWQ::CORE::ROUTER::TABLE

