import ballerinax/kafka;
import ballerina/io;
import ballerinax/mongodb;
import ballerina/lang.runtime;

// Kafka configurations
kafka:ConsumerConfiguration consumerConfig = {
    bootstrapServers: "kafka:29092",
    groupId: "standard-delivery-group",
    topics: ["delivery-requests"]
};

kafka:ProducerConfiguration producerConfig = {
    bootstrapServers: "kafka:29092",
    clientId: "standard-delivery-producer",
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

service "standard-delivery-consumer" on new kafka:Listener(consumerConfig) {
    remote function onConsumerRecord(kafka:ConsumerRecord[] records) returns error? {
        kafka:Producer kafkaProducer = check new (producerConfig);
        
        foreach var record in records {
            json|error payload = check string:fromBytes(record.value).fromJsonString();
            if payload is json {
                if payload.deliveryType == "standard" {
                    // Process standard delivery request
                    io:println("Processing standard delivery request: ", payload.toJsonString());
                    
                    // Update delivery status in the database
                    map<json> filter = { deliveryType: "standard", status: "pending" };
                    map<json> update = { "$set": { status: "scheduled" } };
                    var result = check mongoClient->update("deliveries", filter, update);
                    
                    if result.modifiedCount == 0 {
                        io:println("No pending standard deliveries found to process.");
                        continue;
                    }
                    
                    // Simulate processing time
                    runtime:sleep(2);
                    
                    // Send response
                    json response = {
                        "type": "standard",
                        "status": "scheduled",
                        "estimatedDeliveryTime": "2-3 business days"
                    };
                    check kafkaProducer->send({
                        topic: "delivery-responses",
                        value: response.toJsonString().toBytes()
                    });
                }
            }
        }
    }
}