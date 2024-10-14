import ballerinax/kafka;
import ballerina/io;
import ballerinax/mongodb;

// Kafka configurations
kafka:ConsumerConfiguration consumerConfig = {
    bootstrapServers: "kafka:29092",
    groupId: "express-delivery-group",
    topics: ["delivery-requests"]
};

kafka:ProducerConfiguration producerConfig = {
    bootstrapServers: "kafka:29092",
    clientId: "express-delivery-producer",
    acks: "all",
    retryCount: 3
};

// MongoDB configurations
mongodb:Client mongoClient = check new ("mongodb", 27017, {
    auth: {
        username: "",
        password: ""
    },
    database: "logistics_db"
});

service "express-delivery-consumer" on new kafka:Listener(consumerConfig) {
    remote function onConsumerRecord(kafka:ConsumerRecord[] records) returns error? {
        kafka:Producer kafkaProducer = check new (producerConfig);
        
        foreach var record in records {
            json|error payload = record.value.fromBytes().fromJson();
            if payload is json {
                if payload.deliveryType == "express" {
                    // Process express delivery request
                    io:println("Processing express delivery request: ", payload.toJsonString());
                    
                    // Update delivery status in the database
                    map<json> filter = { deliveryType: "express", status: "pending" };
                    map<json> update = { "$set": { status: "scheduled" } };
                    var result = check mongoClient->update(update, "deliveries", filter, true, false, 1);
                    
                    if result.modifiedCount == 0 {
                        io:println("No pending express deliveries found to process.");
                        continue;
                    }
                    
                    // Simulate processing time
                    runtime:sleep(1);
                    
                    // Send response
                    json response = {
                        "type": "express",
                        "status": "scheduled",
                        "estimatedDeliveryTime": "Next day delivery"
                    };
                    check kafkaProducer->send({
                        topic: "delivery-responses",
                        value: response
                    });
                }
            }
        }
    }
}