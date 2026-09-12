# Target application.
TARGET := frame_test

# C++ compiler.
CXX_COMPILER := g++

# The qacademy::test framework, checked out as a submodule at the repository root.
TEST_LIB_DIR := ../../../libs/test
TEST_LIB     := $(TEST_LIB_DIR)/libqacademy_test.a

# Source files.
SRC_FILES := source/comm/frame/frame.cpp \
             source/comm/frame/parser.cpp

# Test files.
TST_FILES := test/main.cpp \
             test/comm/frame/frame_test.cpp \
             test/comm/frame/parser_test.cpp

# All files.
ALL_FILES := $(SRC_FILES) $(TST_FILES)

# Include directories: this demo's headers and the test framework's.
INC_DIR := -Iinclude -I$(TEST_LIB_DIR)/include

# C++ flags.
CXX_FLAGS := -Wall -Wextra -Werror -std=c++17 $(INC_DIR)

# Build and run the test suite by default.
default: build test

# Build the test framework, then the test suite.
build: $(TEST_LIB)
	@$(CXX_COMPILER) $(ALL_FILES) -o $(TARGET) $(CXX_FLAGS) -L$(TEST_LIB_DIR) -lqacademy_test

# Build the static library the test suite links against.
$(TEST_LIB):
	@$(MAKE) --no-print-directory -C $(TEST_LIB_DIR) lib

# Run the test suite.
test:
	@./$(TARGET)

# Clean build artifacts.
clean:
	@rm -f $(TARGET)
	@$(MAKE) --no-print-directory -C $(TEST_LIB_DIR) clean

.PHONY: default build test clean
