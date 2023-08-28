export const dataFormatter = (number) => {
    return "$ " + Intl.NumberFormat("us").format(number).toString()
}