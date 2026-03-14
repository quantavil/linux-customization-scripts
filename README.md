# Linux Customization Scripts

This repository contains a collection of scripts, configurations, and automation tools designed to customize and enhance a Linux system environment.

## Overview

The purpose of this repository is to modularize the setup of various tools and services. Each independent module is contained within its own directory and automates the installation, configuration, and teardown of a specific application or system component.

## Repository Structure

Each folder in this repository represents a standalone component. Inside each directory, you will typically find:

- A `README.md` explaining the specific component's purpose.
- `apply_<name>_setup.sh`: A script to automate the installation and configuration of the component.
- `revert_<name>_setup.sh`: A script to remove the configuration and restore the system to its previous state.

## Usage

Navigate to the directory of the tool you wish to configure and follow the instructions in its respective `README.md`. Most setups can be applied simply by running the provided `apply_` script within that directory.

> **Note:** While the scripts strive to automate as much as possible, some tools require manual intervention (e.g., GUI configurations or browser logins). In these cases, the scripts will pause and provide clear, step-by-step instructions on what to do manually before continuing.
