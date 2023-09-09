/**
 * This helper function formats a number into a currency format
 * @param {*} number
 * @returns
 */
export const currencyFormatter = (number) => {
  return '$ ' + Intl.NumberFormat('us').format(number).toString()
}

/**
 * This helper function formats a date into a date format
 * @param {*} date
 * @returns
 */
export const dateFormatter = (date) => {
  return new Date(date).toLocaleDateString()
}

/**
 * This helper function formats a date into a time format
 * @param {*} date
 * @returns
 */
export const timeFormatter = (date) => {
  return new Date(date).toLocaleTimeString()
}

/**
 * This helper function formats a date into a date and time format
 * @param {*} date
 * @returns
 */
export const dateTimeFormatter = (date) => {
  return new Date(date).toLocaleString()
}
