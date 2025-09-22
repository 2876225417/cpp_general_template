
file(GLOB HTTP_SRC   CONFIGURE_DEPENDS http/*.cpp)
file(GLOB ROUTER_SRC CONFIGURE_DEPENDS router/*.cpp)

add_library(core
    SHARED
    ${HTTP_SRC}
    ${ROUTER_SRC}
)

target_include_directories(core
    PUBLIC
    ${CMAKE_SOURCE_DIR}/include/core
)

target_link_libraries(core
    PUBLIC
    Boost::boost
    OpenSSL::SSL
    OpenSSL::Crypto
)









