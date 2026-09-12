/**
 * @brief Test suite entry point.
 */
#include "qacademy/test/test.hpp"

/**
 * @brief Run every registered test case.
 *
 * @return 0 if all tests passed, 1 otherwise.
 */
int main() { return qacademy::test::runAllTests() ? 0 : 1; }
