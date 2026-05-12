#!/usr/bin/env bash

set -e

ACME="$HOME/.acme.sh/acme.sh"
ACME_EMAIL=""
BASE_DOMAIN=""

pause() {
  echo
  read -rp "按 Enter 继续..."
}

need_config() {
  if [ -z "${ACME_EMAIL:-}" ]; then
    read -rp "请输入 ACME 邮箱: " ACME_EMAIL
  fi

  if [ -z "${BASE_DOMAIN:-}" ]; then
    read -rp "请输入主域名，例如 naico.wang: " BASE_DOMAIN
  fi
}

step_1_upgrade() {
  sudo apt update && sudo apt upgrade -y
}

step_2_install_base() {
  sudo apt install -y curl ufw nginx
}

step_3_firewall() {
  sudo ufw allow OpenSSH
  sudo ufw allow 80/tcp
  sudo ufw allow 443/tcp
  sudo ufw allow 7361/tcp
  sudo ufw --force enable
  sudo ufw status
}

step_4_install_acme() {
  need_config
  curl https://get.acme.sh | sh -s email="$ACME_EMAIL"
  "$ACME" --upgrade --auto-upgrade
}

step_5_issue_wildcard_cert() {
  need_config

  echo
  echo "开始签发泛域名证书: *.$BASE_DOMAIN"
  echo

  "$ACME" --issue \
    -d "*.$BASE_DOMAIN" \
    --dns \
    --yes-I-know-dns-manual-mode-enough-go-ahead-please
}

step_6_renew_wildcard_cert() {
  need_config

  echo
  echo "开始续期泛域名证书: *.$BASE_DOMAIN"
  echo

  "$ACME" --renew \
    -d "*.$BASE_DOMAIN" \
    --yes-I-know-dns-manual-mode-enough-go-ahead-please
}

step_7_bind_domain() {
  need_config

  echo
  echo "请先在 DNS 服务商处添加解析："
  echo
  echo "A 记录示例："
  echo "  app.$BASE_DOMAIN  ->  你的服务器 IP"
  echo "  api.$BASE_DOMAIN  ->  你的服务器 IP"
  echo "  fast.$BASE_DOMAIN ->  你的服务器 IP"
  echo
  echo "如果使用 Cloudflare："
  echo "  普通网站 / Nginx 反代：可以开启代理"
  echo "  x-ui / 代理协议端口：建议 DNS only"
}

step_8_install_3x_ui() {
  bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)
}

step_9_install_zsh() {
  sudo apt install -y zsh
}

step_10_set_zsh_default() {
  chsh -s "$(which zsh)"
  echo "已设置 zsh 为默认 shell，重新登录后生效。"
}

step_11_install_starship() {
  curl -sS https://starship.rs/install.sh | sh
}

step_12_init_starship() {
  grep -q 'starship init zsh' ~/.zshrc 2>/dev/null || \
    echo 'eval "$(starship init zsh)"' >> ~/.zshrc

  echo "Starship 已写入 ~/.zshrc"
}

step_13_install_eza() {
  sudo apt install -y eza

  grep -q 'alias ls="eza --icons --group-directories-first"' ~/.zshrc 2>/dev/null || \
    echo 'alias ls="eza --icons --group-directories-first"' >> ~/.zshrc

  grep -q 'alias ll="eza -lah --icons"' ~/.zshrc 2>/dev/null || \
    echo 'alias ll="eza -lah --icons"' >> ~/.zshrc

  echo "eza alias 已写入 ~/.zshrc，重新打开终端后生效。"
}

step_14_issue_domain_cert() {
  echo
  read -rp "请输入要签发证书的域名，例如 api.example.com: " DOMAIN

  "$ACME" --issue \
    -d "$DOMAIN" \
    --dns \
    --yes-I-know-dns-manual-mode-enough-go-ahead-please
}

step_15_renew_domain_cert() {
  echo
  read -rp "请输入要续期证书的域名，例如 api.example.com: " DOMAIN

  "$ACME" --renew \
    -d "$DOMAIN" \
    --yes-I-know-dns-manual-mode-enough-go-ahead-please
}

run_all() {
  need_config

  step_1_upgrade
  step_2_install_base
  step_3_firewall
  step_4_install_acme
  step_7_bind_domain
  step_8_install_3x_ui
  step_9_install_zsh
  step_10_set_zsh_default
  step_11_install_starship
  step_12_init_starship
  step_13_install_eza
}

menu() {
  clear
  echo "Naico Ubuntu 一键安装脚本"
  echo
  echo "1) 升级 Ubuntu"
  echo "2) 安装基础软件 curl / ufw / nginx"
  echo "3) 配置防火墙"
  echo "4) 安装 acme.sh"
  echo "5) 手动签发泛域名证书"
  echo "6) 续期泛域名证书"
  echo "7) 绑定域名说明"
  echo "8) 安装 3x-ui"
  echo "9) 安装 zsh"
  echo "10) 设置 zsh 为默认 shell"
  echo "11) 安装 Starship"
  echo "12) 初始化 Starship"
  echo "13) 安装 eza 彩色文件夹"
  echo "14) 手动签发单域名证书"
  echo "15) 手动续期单域名证书"
  echo "99) 执行推荐全流程"
  echo "0) 退出"
  echo

  read -rp "请选择: " choice

  case "$choice" in
    1) step_1_upgrade ;;
    2) step_2_install_base ;;
    3) step_3_firewall ;;
    4) step_4_install_acme ;;
    5) step_5_issue_wildcard_cert ;;
    6) step_6_renew_wildcard_cert ;;
    7) step_7_bind_domain ;;
    8) step_8_install_3x_ui ;;
    9) step_9_install_zsh ;;
    10) step_10_set_zsh_default ;;
    11) step_11_install_starship ;;
    12) step_12_init_starship ;;
    13) step_13_install_eza ;;
    14) step_14_issue_domain_cert ;;
    15) step_15_renew_domain_cert ;;
    99) run_all ;;
    0) exit 0 ;;
    *) echo "无效选择" ;;
  esac

  pause
  menu
}

case "${1:-menu}" in
  upgrade) step_1_upgrade ;;
  base) step_2_install_base ;;
  firewall) step_3_firewall ;;
  acme) step_4_install_acme ;;
  wildcard-cert) step_5_issue_wildcard_cert ;;
  renew-wildcard) step_6_renew_wildcard_cert ;;
  domain) step_7_bind_domain ;;
  x-ui) step_8_install_3x_ui ;;
  zsh) step_9_install_zsh ;;
  default-zsh) step_10_set_zsh_default ;;
  starship) step_11_install_starship ;;
  init-starship) step_12_init_starship ;;
  eza) step_13_install_eza ;;
  domain-cert) step_14_issue_domain_cert ;;
  renew-domain) step_15_renew_domain_cert ;;
  all) run_all ;;
  menu) menu ;;
  *) echo "未知参数: $1" ;;
esac
