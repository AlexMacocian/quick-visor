# Maintainer: Alex Macocian <amacocian@yahoo.com>
pkgname=quick-visor
pkgver=0.0.1
pkgrel=1
pkgdesc="Quickshell-based display manager overlay for Hyprland"
arch=('any')
url="https://git.estatecloud.org/radumaco/quick-visor"
license=('MIT')
depends=('quickshell' 'qt6-declarative' 'hyprland')
source=("$pkgname-$pkgver.tar.gz::$url/archive/v$pkgver.tar.gz")
sha256sums=('SKIP')

package() {
  cd "$srcdir/$pkgname"

  install -dm755 "$pkgdir/usr/share/$pkgname"
  install -m644 qml/* "$pkgdir/usr/share/$pkgname/"

  install -Dm755 bin/quick-visor "$pkgdir/usr/bin/quick-visor"
  install -Dm755 bin/quick-visor-toggle "$pkgdir/usr/bin/quick-visor-toggle"

  install -Dm644 README.md "$pkgdir/usr/share/doc/$pkgname/README.md"
}
