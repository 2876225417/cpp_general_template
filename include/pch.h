#ifndef PCH_H
#define PCH_H

// ===== 标准库头文件 =====
// 容器
#include <vector>
#include <list>
#include <map>
#include <set>
#include <unordered_map>
#include <unordered_set>
#include <queue>
#include <deque>
#include <stack>
#include <array>

// 算法和迭代器
#include <algorithm>
#include <iterator>
#include <functional>
#include <numeric>

// 字符串和 I/O
#include <string>
#include <iostream>
#include <sstream>
#include <fstream>
#include <iomanip>

// 工具
#include <memory>
#include <utility>
#include <tuple>
#include <optional>
#include <variant>
#include <any>
#include <type_traits>
#include <typeinfo>
#include <chrono>
#include <random>
#include <limits>
#include <cmath>
#include <cassert>
#include <exception>
#include <stdexcept>

// 多线程
#include <condition_variable>
#include <thread>
#include <atomic>

// ===== 项目通用工具 =====
#include <utils/non-copyable.h>
#include <utils/singleton.h>
#include <utils/action_types.h>

#endif // PCH_H