---
layout: post
title:  "Web3 Smart Contracts"
date:   2024-12-01 08:00:00 -0400
categories:
  - projects
  - web3
---

<img src="/assets/images/bocacontracts-main.png" alt="Alt text for the image" style="float: left; width: 400px; margin-right: 25px; margin-bottom: 10px;">

Boca Contracts is a platform that allows anyone to deploy Web3 Smart Contracts based on a set of pre-defined templates. Anyone visiting the site can deploy a smart contract to any of several blockchains.

Boca Contracts is a NextJS application that is deployed on AWS via terraform. It is composed of EC2 instances, load balancers, and an RDS database.

The project is made up of the infrastructure code, the front end code, the application itself, and the Solidity contracts. For now, the application holds contracts in Ethereum (mainnet and Sepolia) and BNB Smart Chain. 

The finished product can be seen here: <a href="https://bocacontracts.com" target="_blank" rel="noopener noreferrer">Boca Contracts Home Page</a>