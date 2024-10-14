import ballerina/io;
import ballerina/http;

public function main() returns error? {
    // Create HTTP client to interact with Logistic Central Hub Service
    http:Client logisticsClient = check new ("http://localhost:9090");

    while true {
        // Display menu
        io:println("\n--- Logistics System Client ---");
        io:println("1. Schedule a delivery");
        io:println("2. Exit");
        string choice = io:readln("Enter your choice (1-2): ");

        if choice == "1" {
            DeliveryRequest request = check getDeliveryDetails();
            json response = check logisticsClient->/request.post(request);
            io:println("\nResponse from server: " + response.toJsonString());
        } else if choice == "2" {
            io:println("Exiting...");
            break;
        } else {
            io:println("Invalid choice. Please try again.");
        }
    }
}

function getDeliveryDetails() returns DeliveryRequest|error {
    io:println("\n--- Enter Delivery Details ---");
    
    string deliveryType = io:readln("Enter delivery type (standard/express/international): ");
    string pickupLocation = io:readln("Enter pickup location: ");
    string deliveryLocation = io:readln("Enter delivery location: ");
    
    io:println("Enter preferred time slots (enter 'done' when finished):");
    string[] preferredTimeSlots = [];
    while true {
        string slot = io:readln("Time slot: ");
        if slot == "done" {
            break;
        }
        preferredTimeSlots.push(slot);
    }
    
    io:println("\n--- Enter Customer Information ---");
    string firstName = io:readln("Enter first name: ");
    string lastName = io:readln("Enter last name: ");
    string contactNumber = io:readln("Enter contact number: ");

    return {
        deliveryType: deliveryType,
        pickupLocation: pickupLocation,
        deliveryLocation: deliveryLocation,
        preferredTimeSlots: preferredTimeSlots,
        customerInfo: {
            firstName: firstName,
            lastName: lastName,
            contactNumber: contactNumber
        }
    };
}

type DeliveryRequest record {
    string deliveryType;
    string pickupLocation;
    string deliveryLocation;
    string[] preferredTimeSlots;
    CustomerInfo customerInfo;
};

type CustomerInfo record {
    string firstName;
    string lastName;
    string contactNumber;
};