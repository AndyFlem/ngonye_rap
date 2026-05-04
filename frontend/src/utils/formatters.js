export const formatCurrency = (value) => {
  if (value == null || isNaN(value)) return '0'
  return Math.round(Number(value)).toLocaleString('en-US')
}

export const formatArea = (value) => {
  if (value == null || isNaN(value)) return '0'
  return Math.round(Number(value)).toLocaleString('en-US') + ' sqm'
}

export const formatYesNo = (value) => {
  if (value === true) return 'Yes'
  if (value === false) return 'No'
  return 'Unknown'
}
