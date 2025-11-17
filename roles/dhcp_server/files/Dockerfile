FROM alpine:3.18
RUN apk add --no-cache dhcp
COPY dhcpd.conf /etc/dhcp/dhcpd.conf
EXPOSE 67/udp
CMD ["dhcpd", "-f", "-d", "-cf", "/etc/dhcp/dhcpd.conf"]
