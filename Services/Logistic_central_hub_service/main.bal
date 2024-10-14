import ballerina/http;
import ballerinax/kafka;
import ballerina/io;
import ballerinax/mongodb;

// Kafka configurations
kafka:ProducerConfiguration producerConfig = {
    bootstrapServers: "kafka:29092",
    clientId: "logistics-hub",
    acks: "all",
    retryCount: 3
};

kafka:ConsumerConfiguration consumerConfig = {
    bootstrapServers: "kafka:29092",
    groupId: "logistics-group",
    topics: ["delivery-requests", "delivery-responses"]
};

// MongoDB configurations
mongodb:Client mongoClient = check new ("mongodb", 27017, {
    auth: {
        username: "",
        password: ""
    },
    database: "logistics_db"
});

service / on new http:Listener(9090) {
    resource function post request(@http:Payload DeliveryRequest payload) returns json|error {
        // Create Kafka producer
        kafka:Producer kafkaProducer = check new (producerConfig);
        
        // Store customer info in the database
        map<json> customerDoc = {
            firstName: payload.customerInfo.firstName,
            lastName: payload.customerInfo.lastName,
            contactNumber: payload.customerInfo.contactNumber
        };
        
        var customerInsertResult = check mongoClient->insert(customerDoc, "customers");
        string customerId = customerInsertResult.toString();
        
        // Store delivery info in the database
        map<json> deliveryDoc = {
            customerId: customerId,
            deliveryType: payload.deliveryType,
            pickupLocation: payload.pickupLocation,
            deliveryLocation: payload.deliveryLocation,
            preferredTimeSlot: payload.preferredTimeSlots[0],
            status: "pending"
        };
        
        _ = check mongoClient->insert(deliveryDoc, "deliveries");
        
        // Serialize the request to JSON
        json jsonPayload = payload.toJson();
        
        // Send the request to Kafka
        check kafkaProducer->send({
            topic: "delivery-requests",
            value: jsonPayload.toJsonString().toBytes()
        });
        
        return { "message": "Request received and forwarded to delivery services" };
    }
}

// Kafka consumer service to handle responses from delivery services
service "delivery-response-consumer" on new kafka:Listener(consumerConfig) {
    remote function onConsumerRecord(kafka:ConsumerRecord[] records) returns error? {
        foreach var record in records {
            io:println("Received response: ", check string:fromBytes(record.value));
            // Update delivery status in the database (implementation needed)
        }
    }
}

// Data structures
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