# Vapor SimpleCMS

SimpleCMS is a content manager, simple and performant, it defines the user base and roles of your company. You have customers, suppliers and employees, these will be stored in your contact database with a simple Dashboard where you can manage the interaction with the actors involved in your company. Define a list of products for sale, with a simple interface for inventory management and a dashboard for managing current orders. It has a POS interface to operate in a physical point of sale.

## Dependencies

- Docker
- Docker-compose

## Getting Started

All the services are containerized using docker and docker-compose. To start the project, you need to have docker and docker-compose installed in your machine. Then, you can run the following command to start the project:

If you are looking to run the whole project, you can run the following command:

```bash
docker-compose up
```

In the case you want to run a specific service, you can run the following command:

```bash
docker-compose up <service-name>
```

For development, you can run the following command:

```bash
docker-compose build app
docker-compose up -d
```

This will build the app image and start the containers in the background. You can then run the following command to run the migrations:

```bash
docker-compose run migrate
docker-compose run revert
```

### Required services

- Docker
- Redis
- Postgres
- Vapor
- Ngnix

For the frontend development, nodejs is required. React is used as a frontend framework using vite as a bundler.

## Commands

Build images: docker-compose build
Start reverse proxy: docker-compose up proxy
Start redis: docker-compose up redis
Start app: docker-compose up app
Start database: docker-compose up db
Run migrations: docker-compose run migrate
Stop all: docker-compose down (add -v to wipe db)

# TODOs
 - Add payments providers gateway 
 - Add orders controller 
 - Add transactions controller 
 - Add dashboard controller 
 - Create frontend for managment
 - Create store frontend 
 - Add commands for categories
 - Add commands for orders 
 - Add commands for transactions
 - Add commands for image managment 
 - Create worker for notifications
 - Create basic documentation
 - Create advance documentation
 - Add unit test
 - Add integration tests
 - Add performance tests (wkl)
 - Add configuration json 

## Routes

```
+--------+---------------------------------------------+
| GET    | /                                           |
+--------+---------------------------------------------+
| POST   | /v1/auth/refresh                            |
+--------+---------------------------------------------+
| POST   | /v1/auth/create                             |
+--------+---------------------------------------------+
| GET    | /v1/users                                   |
+--------+---------------------------------------------+
| GET    | /v1/users/create/:option                    |
+--------+---------------------------------------------+
| POST   | /v1/users/create/:option                    |
+--------+---------------------------------------------+
| POST   | /v1/users/:userId/activate                  |
+--------+---------------------------------------------+
| POST   | /v1/users/:userId/deactivate                |
+--------+---------------------------------------------+
| DELETE | /v1/users/:userId                           |
+--------+---------------------------------------------+
| GET    | /v1/categories                              |
+--------+---------------------------------------------+
| DELETE | /v1/categories/:categoryId                  |
+--------+---------------------------------------------+
| POST   | /v1/categories                              |
+--------+---------------------------------------------+
| GET    | /v1/products                                |
+--------+---------------------------------------------+
| POST   | /v1/products                                |
+--------+---------------------------------------------+
| DELETE | /v1/products/:productId                     |
+--------+---------------------------------------------+
| GET    | /v1/products/:productId                     |
+--------+---------------------------------------------+
| POST   | /v1/products/:productId/reviews             |
+--------+---------------------------------------------+
| GET    | /v1/products/:productId/reviews             |
+--------+---------------------------------------------+
| DELETE | /v1/products/:productId/reviews/:reviewId   |
+--------+---------------------------------------------+
| PATCH  | /v1/products/:productId/reviews/:reviewId   |
+--------+---------------------------------------------+
| POST   | /v1/products/:productId/variants            |
+--------+---------------------------------------------+
| DELETE | /v1/products/:productId/variants/:variantId |
+--------+---------------------------------------------+
| PATCH  | /v1/products/:productId/variants/:variantId |

```
