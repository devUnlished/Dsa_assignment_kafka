FROM ballerina/ballerina:2201.10.1

WORKDIR /app

COPY . /app

RUN bal build

CMD ["bal", "run", "target/bin/international_delivery_microservice.jar"]