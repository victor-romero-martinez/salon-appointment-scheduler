#!/bin/bash

PSQL="psql -U freecodecamp -d salon --tuples-only -c"

# global vars
CUSTOMER_NAME=''
CUSTOMER_PHONE=''
CUSTOMER_ID=0
SERVICE_NAME=''
SERVICE_ID_SELECTED=0

echo -e "\n~~~~~ MY SALON ~~~~~"

# greeting
echo -e "\nWelcome to My Salon, how can I help you?\n"

function MAIN() {
  # handling message
  MESSAGE=$1

  if [[ $MESSAGE ]]; then
    echo -e "\n$MESSAGE"
  fi

  # get service list
  SERVICES_LIST=$($PSQL "SELECT * FROM services")
  echo "$SERVICES_LIST" | while read ID BAR NAME; do
    echo "$ID) $NAME"
  done

  # get input
  read SERVICE_ID_SELECTED

  # if not a number
  if [[ ! $SERVICE_ID_SELECTED =~ ^[1-9]+$ ]]; then
    # send to main
    MAIN "I could not find that servie. What would you like today?"
  else
   # get service name from db
    SERVICE_NAME=$($PSQL "SELECT name FROM services WHERE service_id = $SERVICE_ID_SELECTED" | sed 's/ //')

    # if not found
    if [[ -z $SERVICE_NAME ]]; then
      MAIN "I could not find that servie. What would you like today?"
    else
      PHONE_INPUT
      
      # find user by phone
      CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE phone = '$CUSTOMER_PHONE'" | sed 's/ //')

      # if not exist
      if [[ -z $CUSTOMER_NAME ]]; then
        # create customer
        CREATE_CUSTOMER
        CREATE_APPOINTMENT
      else
        # create appoiment
        CREATE_APPOINTMENT
      fi
    fi
  fi
}

# handler phone input
function PHONE_INPUT() {
  if [[ $1 ]]; then
    echo -e "\n$1"
  else
    echo -e "\nWhat's your phone number"
  fi
  
  read CUSTOMER_PHONE

  if [[ -z $CUSTOMER_PHONE ]]; then
    PHONE_INPUT "Try again"
  fi
}

# create user
function CREATE_CUSTOMER() {
  if [[ $1 ]]; then
    echo -e "\n$1"
  else
    echo -e "\nI don't have a record for that phone number, what's your name?"
  fi

  read CUSTOMER_NAME

  if [[ -z $CUSTOMER_NAME ]]; then
    CREATE_CUSTOMER "The field cannot be empty, please try again."
  else
    # insert a new customer
    # no se si tiene sentido capturar el resultado
    INSERT_RESULT=$($PSQL "INSERT INTO customers(name, phone) VALUES('$CUSTOMER_NAME', '$CUSTOMER_PHONE')")
    # find user by phone
    CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE phone = '$CUSTOMER_PHONE'" | sed 's/ //')
  fi
}

# get customer_id by phone
function GET_CUSTOMER_ID() {
  CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone = '$CUSTOMER_PHONE'")
}

function CREATE_APPOINTMENT() {
  if [[ $1 ]]; then
    echo -e "\n$1"
  else
    echo -e "\nWhat time would you like $SERVICE_NAME, $CUSTOMER_NAME."
  fi

  read SERVICE_TIME

  if [[ $SERVICE_TIME ]]; then
    GET_CUSTOMER_ID

    # insert an appointment
    APPOINTMENT_RESULT=$($PSQL "INSERT INTO appointments(customer_id, service_id, time) VALUES($CUSTOMER_ID, $SERVICE_ID_SELECTED, '$SERVICE_TIME')")

    # end program
    echo -e "\nI have put you down for a $SERVICE_NAME at $SERVICE_TIME, $CUSTOMER_NAME."
  else
    CREATE_APPOINTMENT "Is required a time."
  fi
}

MAIN
