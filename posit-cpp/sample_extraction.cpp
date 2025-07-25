#include <iostream>
#include <bitset>
#include <random>
#include <ctime>
#include <vector>
#include <fstream>

#include "posit_util.h" 

// Function to convert a vector<bool> to a binary string
std::string vectorToBinaryString(const std::vector<bool>& v) {
    std::string binaryString;
    for (bool bit : v) {
        binaryString.push_back(bit ? '1' : '0');
    }
    return binaryString;
}

std::vector<bool> doubleToPosit8(double value) {
    // Scale and bias adjustment (placeholder, specific logic needed)
    int exponent;
    double fraction = std::frexp(value, &exponent); // Breaks the double into normalized fraction [0.5, 1) and an exponent
    int scaledValue = std::ldexp(fraction, 8) + exponent; // Naively map the range

    // Assume the scaledValue now fits an 8-bit format
    std::bitset<8> bits(abs(scaledValue)); // Convert to bitset, simplifying the sign handling
    if (value < 0) {
        bits.flip(); // Simple negation example
    }

    std::vector<bool> result(8);
    for (size_t i = 0; i < 8; ++i) {
        result[i] = bits[i];
    }
    return result;
}

int main() {
    std::ofstream csvFile("posit8_addition_results.csv");
    csvFile << "Posit1,Posit2,Result\n"; // Headers for the CSV file

    std::srand(static_cast<unsigned int>(std::time(nullptr))); // Seed the random number generator
    int es = 2; // Exponent size
    int sample_size = 100;

    for (int i = 0; i < sample_size; ++i) {
        // Generate random 8-bit Posit values
        std::bitset<8> posit1Bitset(std::rand() % 256);
        std::bitset<8> posit2Bitset(std::rand() % 256);

        // Convert bitsets to Posit type using your utility functions
        std::vector<bool> posit1 = MyPosit::bitsetToVector8(posit1Bitset); // Modify according to actual function
        std::vector<bool> posit2 = MyPosit::bitsetToVector8(posit2Bitset); // Modify according to actual function

        MyPosit p1(posit1, 8, es); 
        MyPosit p2(posit2, 8, es); 

        // Perform addition of p1 and p2 using your Posit arithmetic method
        MyPosit result = p1.add(p1, p2); // Adjust according to actual API
        // std::vector<bool> result_bool = doubleToPosit8(result.getDouble()); // Get the result as a double
        std::vector<bool> result_bool = result.getVectorBool();

        std::string binaryPosit1 = vectorToBinaryString(posit1);
        std::string binaryPosit2 = vectorToBinaryString(posit2);
        std::string binaryResult = vectorToBinaryString(result_bool);

        std::cout << "result: " << binaryResult << std::endl;

        csvFile << binaryPosit1 << "," 
        << binaryPosit2 << "," 
        << binaryResult << "\n";

    }

    csvFile.close();
    std::cout << "Generated and saved 10 random Posit additions to 'posit_addition_results.csv'\n";


    // g++ -std=c++20 sample_extraction.cpp posit_util.cpp -o main
    // ./main
    return 0;
}