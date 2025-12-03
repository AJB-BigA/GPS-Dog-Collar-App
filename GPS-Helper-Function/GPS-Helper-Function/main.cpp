//
//  main.cpp
//  GPS-Helper-Function
//
//  Created by Austin Baker on 3/12/2025.
//

#include <iostream>
#include "Helper.hpp"
#include <tuple>
using namespace std;

int main(int argc, const char * argv[]) {

    cout<<"start"<<endl;
    int num = 0;
    string input[3] = {"AT+CGNSINF\n+CGNSINF: 1,0,,,,,,,,,,,,,,,,,,, \nOK","AT+CGNSINF \n +CGNSINF: 1,1,20251203,095433.000,-33.889120,151.199950,45.6,0.12,270.3,1,0.9,1.3,0.7,0,10,7,3,0,38,1.2,1.8 \nOK","AT+CGNSINF \n +CGNSINF: 1,1,20251203,095433.000,-33.889120,152.199950,45.6,0.12,270.3,1,0.9,1.3,0.7,0,10,7,3,0,38,1.2,1.8 \nOK"};
    cout<<"check for values"<<endl;
    while (num < 100000){
        if(checkIfSatLock(input[num]) == true){
            break;
        };
        num++;
    }
    cout<<"print lat and long"<<endl;
    string lat;
    string lng;
    auto cords = getLatAndLong(input[num]);
    string payload = "{";
      payload += "\"device_id\":\"Nala\",";
      payload += "\"lat\":"+cords.first+",";
      payload += "\"lng\":"+cords.second+",";
      payload += "\"bat\":90,";
      payload += "\"status\":true";
      payload += "}";
    cout<<payload<<endl;
    
    return 0;
}
