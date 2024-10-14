db = db.getSiblingDB('logistics_db');

db.createCollection('customers');
db.createCollection('deliveries');

db.customers.createIndex({ "contactNumber": 1 }, { unique: true });
db.deliveries.createIndex({ "deliveryType": 1 });
db.deliveries.createIndex({ "status": 1 });

print("MongoDB collections and indexes created successfully.");