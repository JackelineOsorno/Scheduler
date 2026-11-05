#! /bin/bash
set -e

PSQL="psql --username=freecodecamp --dbname=salon --no-align --tuples-only --quiet --set=ON_ERROR_STOP=1"

echo -e "\n~~~~~ MY SALON ~~~~~\n"
echo -e "\nWelcome to My Salon, how can I help you?\n"

while true; do
  SERVICES=$($PSQL -c "SELECT service_id || ') ' || name FROM services ORDER BY service_id;")
  printf '%s\n' "$SERVICES"
  read SERVICE_ID_SELECTED

  if [[ "$SERVICE_ID_SELECTED" =~ ^[0-9]+$ ]]; then
    SERVICE_NAME=$($PSQL -c "SELECT name FROM services WHERE service_id = $SERVICE_ID_SELECTED;")
  else
    SERVICE_NAME=
  fi

  if [[ -n "$SERVICE_NAME" ]]; then
    break
  fi

  echo -e "\nI could not find that service. What would you like today?"
done

echo -e "\nWhat's your phone number?"
read CUSTOMER_PHONE

CUSTOMER_ID=$(psql --username=freecodecamp --dbname=salon --no-align --tuples-only --quiet --set=ON_ERROR_STOP=1 -v customer_phone="$CUSTOMER_PHONE" -f <(printf '%s\n' "SELECT customer_id FROM customers WHERE phone = :'customer_phone';"))

if [[ -z "$CUSTOMER_ID" ]]; then
  echo -e "\nI don't have a record for that phone number, what's your name?"
  read CUSTOMER_NAME
  CUSTOMER_ID=$(psql --username=freecodecamp --dbname=salon --no-align --tuples-only --quiet --set=ON_ERROR_STOP=1 -v customer_name="$CUSTOMER_NAME" -v customer_phone="$CUSTOMER_PHONE" -f <(printf '%s\n' "INSERT INTO customers (name, phone) VALUES (:'customer_name', :'customer_phone') RETURNING customer_id;"))
else
  CUSTOMER_NAME=$(psql --username=freecodecamp --dbname=salon --no-align --tuples-only --quiet --set=ON_ERROR_STOP=1 -v customer_phone="$CUSTOMER_PHONE" -f <(printf '%s\n' "SELECT name FROM customers WHERE phone = :'customer_phone';"))
fi

echo -e "\nWhat time would you like your $SERVICE_NAME, $CUSTOMER_NAME?"
read SERVICE_TIME

psql --username=freecodecamp --dbname=salon --no-align --tuples-only --quiet --set=ON_ERROR_STOP=1 -v service_time="$SERVICE_TIME" -f <(printf '%s\n' "INSERT INTO appointments (customer_id, service_id, time) VALUES ($CUSTOMER_ID, $SERVICE_ID_SELECTED, :'service_time');") > /dev/null

echo -e "\nI have put you down for a $SERVICE_NAME at $SERVICE_TIME, $CUSTOMER_NAME."