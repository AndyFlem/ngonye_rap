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
  return 'No'
}

export const copyTableAsCsv = (tableEl) => {
  const headerCells = Array.from(tableEl.querySelectorAll('thead tr:last-child th'))
  const headers = headerCells.map(th => tsvEscape(th.innerText.trim()))

  const dataRows = Array.from(tableEl.querySelectorAll('tbody tr'))
    .filter(tr => !tr.querySelector('table'))
    .map(tr =>
      Array.from(tr.querySelectorAll('td'))
        .map(td => tsvEscape(td.innerText.trim()))
        .join('\t')
    )

  const tsv = [headers.join('\t'), ...dataRows].join('\n')
  return navigator.clipboard.writeText(tsv)
}

function tsvEscape(value) {
  return value.replace(/[\t\n\r]/g, ' ')
}
