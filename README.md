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

   - [X] Add payments providers gateway
      - [X] Added Wompi provider (COL)
   - [X] Add orders controller
   - [X] Add transactions controller
   - [X] Add POS frontend
   - [X] Add POS controller
   - [X] Add dashboard controller
   - [X] Create frontend for managment
   - Create store frontend
   - Add commands for categories
   - Add commands for orders
   - Add commands for transactions
   - Add commands for image managment
   - [X] Add finance controller
   - Create worker for notifications
   - Create basic documentation
   - Create advance documentation
   - Add unit test
   - Add integration tests
   - Add performance tests (wkl)
   - [X] Add configuration json
   - Refactor controllers
      - Refactor models
      - Refactor routes
      - Refactor controllers
      - Refactor middlewares
      - Refactor services
   - Refactor frontend
      - Refactor components
      - Refactor pages
      - Refactor hooks
      - Refactor services
      - Refactor utils
      - Refactor styles
   - [X] Add docker-compose for development
   - Add docker-compose for production

## Routes

```
+--------+-------------------------------------------------------------+
| GET    | /                                                           |
+--------+-------------------------------------------------------------+
| POST   | /v1/auth/refresh                                            |
+--------+-------------------------------------------------------------+
| POST   | /v1/auth/create                                             |
+--------+-------------------------------------------------------------+
| POST   | /v1/users/create                                            |
+--------+-------------------------------------------------------------+
| GET    | /v1/users/available/roles                                   |
+--------+-------------------------------------------------------------+
| GET    | /v1/users/available/national/ids                            |
+--------+-------------------------------------------------------------+
| GET    | /v1/users/me                                                |
+--------+-------------------------------------------------------------+
| POST   | /v1/users/create/employee                                   |
+--------+-------------------------------------------------------------+
| POST   | /v1/users/create/provider                                   |
+--------+-------------------------------------------------------------+
| POST   | /v1/users/:userId/activate                                  |
+--------+-------------------------------------------------------------+
| POST   | /v1/users/:userId/deactivate                                |
+--------+-------------------------------------------------------------+
| DELETE | /v1/users/:userId                                           |
+--------+-------------------------------------------------------------+
| GET    | /v1/users/all/employees                                     |
+--------+-------------------------------------------------------------+
| GET    | /v1/users/all/providers                                     |
+--------+-------------------------------------------------------------+
| GET    | /v1/users/all/clients                                       |
+--------+-------------------------------------------------------------+
| GET    | /v1/categories                                              |
+--------+-------------------------------------------------------------+
| DELETE | /v1/categories/:categoryId                                  |
+--------+-------------------------------------------------------------+
| POST   | /v1/categories                                              |
+--------+-------------------------------------------------------------+
| GET    | /v1/products                                                |
+--------+-------------------------------------------------------------+
| GET    | /v1/products/:productId                                     |
+--------+-------------------------------------------------------------+
| POST   | /v1/products                                                |
+--------+-------------------------------------------------------------+
| DELETE | /v1/products/:productId                                     |
+--------+-------------------------------------------------------------+
| PATCH  | /v1/products/:productId                                     |
+--------+-------------------------------------------------------------+
| GET    | /v1/products/pos                                            |
+--------+-------------------------------------------------------------+
| GET    | /v1/products/:productId/reviews                             |
+--------+-------------------------------------------------------------+
| POST   | /v1/products/:productId/reviews                             |
+--------+-------------------------------------------------------------+
| DELETE | /v1/products/:productId/reviews/:reviewId                   |
+--------+-------------------------------------------------------------+
| PATCH  | /v1/products/:productId/reviews/:reviewId                   |
+--------+-------------------------------------------------------------+
| GET    | /v1/products/:productId/variants                            |
+--------+-------------------------------------------------------------+
| GET    | /v1/products/:productId/variants/:variantId                 |
+--------+-------------------------------------------------------------+
| POST   | /v1/products/:productId/variants                            |
+--------+-------------------------------------------------------------+
| DELETE | /v1/products/:productId/variants/:variantId                 |
+--------+-------------------------------------------------------------+
| PATCH  | /v1/products/:productId/variants/:variantId                 |
+--------+-------------------------------------------------------------+
| GET    | /v1/products/:productId/variants/sku                        |
+--------+-------------------------------------------------------------+
| GET    | /v1/products/:productId/questions                           |
+--------+-------------------------------------------------------------+
| POST   | /v1/products/:productId/questions                           |
+--------+-------------------------------------------------------------+
| DELETE | /v1/products/:productId/questions/:questionId               |
+--------+-------------------------------------------------------------+
| PATCH  | /v1/products/:productId/questions/:questionId               |
+--------+-------------------------------------------------------------+
| POST   | /v1/orders/checkout                                         |
+--------+-------------------------------------------------------------+
| GET    | /v1/orders/mine                                             |
+--------+-------------------------------------------------------------+
| GET    | /v1/orders/all                                              |
+--------+-------------------------------------------------------------+
| GET    | /v1/orders/pending                                          |
+--------+-------------------------------------------------------------+
| GET    | /v1/orders/payed                                            |
+--------+-------------------------------------------------------------+
| GET    | /v1/orders/placed                                           |
+--------+-------------------------------------------------------------+
| GET    | /v1/orders/stats                                            |
+--------+-------------------------------------------------------------+
| POST   | /v1/orders/checkout/:method                                 |
+--------+-------------------------------------------------------------+
| GET    | /v1/transactions/payment/callback/:provider                 |
+--------+-------------------------------------------------------------+
| GET    | /v1/transactions/payment/pay/:provider/:transactionId       |
+--------+-------------------------------------------------------------+
| POST   | /v1/finance/costs                                           |
+--------+-------------------------------------------------------------+
| GET    | /v1/finance/costs/fixed                                     |
+--------+-------------------------------------------------------------+
| GET    | /v1/finance/costs/variable                                  |
+--------+-------------------------------------------------------------+
| GET    | /v1/finance/costs/all                                       |
+--------+-------------------------------------------------------------+
| GET    | /v1/finance/costs                                           |
+--------+-------------------------------------------------------------+
| DELETE | /v1/finance/costs/:costId                                   |
+--------+-------------------------------------------------------------+
| PATCH  | /v1/finance/costs/:costId                                   |
+--------+-------------------------------------------------------------+
| GET    | /v1/finance/costs/:costId                                   |
+--------+-------------------------------------------------------------+
| GET    | /v1/finance/sales                                           |
+--------+-------------------------------------------------------------+
| GET    | /v1/finance/sales/all                                       |
+--------+-------------------------------------------------------------+
| GET    | /v1/countries                                               |
+--------+-------------------------------------------------------------+
| GET    | /v1/products/:productId/variants/:variantId/images          |
+--------+-------------------------------------------------------------+
| POST   | /v1/products/:productId/variants/:variantId/images          |
+--------+-------------------------------------------------------------+
| POST   | /v1/products/:productId/variants/:variantId/images/multiple |
+--------+-------------------------------------------------------------+
| DELETE | /v1/products/:productId/variants/:variantId/images          |
+--------+-------------------------------------------------------------+
| GET    | /v1/settings                                                |
+--------+-------------------------------------------------------------+
| PATCH  | /v1/settings                                                |
+--------+-------------------------------------------------------------+
| GET    | /v1/settings/flags                                          |
+--------+-------------------------------------------------------------+
| PATCH  | /v1/settings/flags/:flag                                    |
+--------+-------------------------------------------------------------+

```
