# Vapor Ecommerce: A Simple, Performant and Scalable Swifty-Ecommerce Platform

[Image](https://placehold.it/700x300)

## Table of Contents

- [What is Vapor Ecommerce?](#what-is-vapor-ecommerce)
- [Getting Started](#getting-started)
   - [Prerequisites](#prerequisites)
      - [For development](#for-development)
   - [Setup](#setup)
      - [deploy.sh modes](#deploysh-modes)
      - [Running without deploy.sh](#running-without-deploysh)
   - [Commands](#commands)
- [TODOs](#todos)
- [Routes](#routes)

## What is Vapor Ecommerce?

*Vapor-Ecommerce* is a content manager, simple and performant, it defines the user base and roles of your company. You have customers, suppliers and employees, these will be stored in your contact database with a simple Dashboard where you can manage the interaction with the actors involved in your company. Define a list of products for sale, with a simple interface for inventory management and a dashboard for managing current orders. It has a POS interface to operate in a physical point of sale.

## Getting Started

### Prerequisites

This project is full dockerized, so you need to have docker and docker-compose installed in your machine. You can follow the instructions in the following links: [Docker](https://docs.docker.com/get-docker/) and [Docker-compose](https://docs.docker.com/compose/install/) to install them.

#### For development

This project uses Vapor as a backend framework, so you need to have it installed in your machine. You can follow the instructions in the following link: [Vapor](https://docs.vapor.codes/4.0/install/macos/).

### Setup

This repository contains a docker-compose file to run the project. In order to build and run the vapor stack, there is an `deploy.sh` script that will build the images and run the containers. You can run the following command to start the project:

```bash
./deploy.sh -d     # This runs the project for development mode (see info about development mode below)
./deploy.sh -p     # This runs the project for production mode
```

**There are some containers on the docker-compose that conforms the stack:**

Main service:

- **vapor**: This is the main container, it contains the vapor project and it is the main container of the stack. It is the one that will run the vapor server.

Required services:

- **db**: This is the database container, it contains the postgres database.
- **redis**: This is the redis container, it contains the redis database.

Optional services:

- **pgadmin**: This is the pgadmin container, it contains the pgadmin interface to manage the postgres database.
- **redis-commander**: This is the redis-commander container, it contains the redis-commander interface to manage the redis database.

#### deploy.sh modes

The `deploy.sh` script has two modes: development and production.
**-d** or **development**: This mode will run the following services:

- **db**
- **redis**

Note: The vapor container won't be run in this mode, so you need to run it manually. Use `swift run` to run the vapor server locally. Or use Xcode to run the project.
WARINING: Since the main container is running on Linux, keep in mind compatibility issues with the Swift Foundation for macOS and Linux.

**-p** or **production**: This mode will run the following services:

- **vapor**
- **db**
- **redis**
- **pgadmin**
- **redis-commander**

Note: By default vapor container will be defined to use two replicas, so you can scale it up or down as you need.

#### Running without deploy.sh

Since the whole project depends on docker-compose, you can run the project without the `deploy.sh` script. You can run the following command to start the project:

```bash
# Docker Compose file for Vapor
#
# Install Docker on your system to run and test
# your Vapor app in a production-like environment.
#
# Note: This file is intended for testing and does not
# implement best practices for a production deployment.
#
# Learn more: https://docs.docker.com/compose/reference/
#
#   Build images: docker-compose build
#      Start app: docker-compose up app
# Start database: docker-compose up db
# Run migrations: docker-compose run migrate
#       Stop all: docker-compose down (add -v to wipe db)
#
```

## Commands

Vapor defines a set of commands to manage the project. You can run the following command to see the list of commands:

```bash
swift run App help # This will show the list of commands
swift run App users create # This will create a user
```

## TODOs

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

```text
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
