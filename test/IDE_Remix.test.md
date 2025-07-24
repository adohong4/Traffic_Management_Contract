example:
issue Driver License: tuple ["ABC123460", 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB, "HOLDER003", "Juwngkog", "B", 1672531200, 1704067200, "AUTH001", 12]
// expiryDate < 1753290000 (đã hết hạn)
  ["ABC100001", 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2, "HOLDER001", "Nguyen Van A", "B", 1672531200, 1700000000, "AUTH001", 12]
  
  // expiryDate > 1753290000 (còn hiệu lực)
  ["ABC100002", 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4, "HOLDER002", "Le Thi B", "B", 1680000000, 1760000000, "AUTH002", 12]
  
  // expiryDate = hôm nay (có thể coi là hết hạn nếu kiểm tra `expiryDate < block.timestamp`)
  ["ABC100003", 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db, "HOLDER003", "Tran Van C", "C1", 1688888888, 1753290000, "AUTH003", 12]
  
  // expiryDate > hôm nay
  ["ABC100004", 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB, "HOLDER004", "Pham Thi D", "D2", 1690000000, 1800000000, "AUTH004", 12]

  // expiryDate < hôm nay
  ["ABC100005", 0x617F2E2fD72FD9D5503197092aC168c91465E7f2, "HOLDER005", "Dang Van E", "E1", 1672531200, 1740000000, "AUTH005", 12]

Deduct Point: License_No: ABC123456, tuple ["Ma123", 1]

Update Driver License: tuple: ["ABC123460", 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB, "Juwngkog", "A1", 1837443600, 2, 12]