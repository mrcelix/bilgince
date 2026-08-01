---
baslik: "MFA'ya kaydolmamış kullanıcılar"
ozet: "Koşullu erişimi zorlamadan önce kimlerin henüz yöntem kaydetmediğini gösterir."
konu: "guvenlik"
etiketler: ["entra-id", "mfa"]
kod: |
  Connect-MgGraph -Scopes 'UserAuthenticationMethod.Read.All'
  Get-MgReportAuthenticationMethodUserRegistrationDetail -All |
    Where-Object { -not $_.IsMfaRegistered } |
    Select-Object UserPrincipalName, UserDisplayName |
    Sort-Object UserPrincipalName
dikkat: "Yayımdan önce bu listeyi sıfırlayın; kayıtsız kullanıcı politika açıldığında dışarıda kalır."
ilgiliRehber: "entra-id-mfa-zorlama"
---
