#include <iostream>
#include <bitset>
#include <cstdint>
#include "posit_util.h"

int main() {
    // Example POSIT values using bitsets
    std::bitset<8> posit1Bitset("01001011"); // POSIT1:
    std::bitset<8> posit2Bitset("10000100"); // POSIT2:

    // Convert bitsets to vectors
    std::vector<bool> posit1 = MyPosit::bitsetToVector8(posit1Bitset);
    std::vector<bool> posit2 = MyPosit::bitsetToVector8(posit2Bitset);

    int es = 1; // Exponent size

    MyPosit p1(posit1, 8, es);
    MyPosit p2(posit2, 8, es);

    std::cout << "---- posit_a : " << std::endl;
    p1.printDouble();
    p1.printComponents();

    std::cout << "\n";
    std::cout << "\n";

    std::cout << "---- posit_b : " << std::endl;
    p2.printDouble();
    p2.printComponents();

    // std::bitset<16> posit3Bit("0110010101010000");
    // std::vector<bool> posit3 = MyPosit::bitsetToVector16(posit3Bit);
    // MyPosit p3(posit3, 16, es);

    // std::cout << "---- posit_c : " << std::endl;
    // p3.printDouble();

    std::cout << "\n";
    std::cout << "\n";

    // Perform addition of p1 and p2
    // MyPosit result = p1.add(p1, p2);
    // std::cout << "Result of p1 + p2:" << std::endl;
    // result.printDouble();
    // result.printComponents();

    MyPosit result = p1.mul(p1, p2);
    std::cout << "Result of p1 * p2:" << std::endl;
    result.printDouble();
    result.printComponents();

    // how to run
    // g++ -std=c++20 main.cpp posit_util.cpp -o main
    // ./main
    return 0;
}