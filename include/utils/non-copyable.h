#ifndef NON_COPYABLE_H
#define NON_COPYABLE_H

class NonCopyable {
protected:
    explicit NonCopyable() = default;
    ~NonCopyable() = default;
public:
    NonCopyable(const NonCopyable&) = delete;
    NonCopyable(NonCopyable&&) noexcept  = delete;
    
    auto operator=(const NonCopyable&) -> NonCopyable& = delete;
    auto operator=(NonCopyable&&) noexcept -> NonCopyable& = delete;
};

#endif // NON_COPYABLE_H