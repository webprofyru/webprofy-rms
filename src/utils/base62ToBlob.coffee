# found in http://stackoverflow.com/questions/16245767/creating-a-blob-from-a-base64-string-in-javascript

module.exports = (b64Data, contentType, sliceSize) ->
  contentType = contentType or ''
  sliceSize = sliceSize or 512
  byteCharacters = atob(b64Data)
  byteArrays = []
  offset = 0
  while offset < byteCharacters.length
    slice = byteCharacters.slice(offset, offset + sliceSize)
    byteNumbers = new Array(slice.length)
    i = 0
    while i < slice.length
      byteNumbers[i] = slice.charCodeAt(i)
      i++
    byteArray = new Uint8Array(byteNumbers)
    byteArrays.push byteArray
    offset += sliceSize
  blob = new Blob(byteArrays, type: contentType)
  blob
