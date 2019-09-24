#!/usr/bin/env bash
function auto_openssl_req {
/usr/bin/expect << EOF
    set timeout 10
    spawn openssl req -new -key dashboard.key -out dashboard.csr
        expect {
            "*" {
                send "\n"
                expect {
                    "*" {
                        send "\n"
                        expect {
                            "*" {
                                send "\n"
                                expect {
                                    "*" {
                                        send "\n"
                                        expect {
                                            "*" {
                                                send "\n"
                                                expect {
                                                    "*" {
                                                        send "\n"
                                                        expect {
                                                            "*" {
                                                                send "\n"
                                                                expect {
                                                                    "*" {
                                                                        send "\n"
                                                                        expect {
                                                                            "*" {
                                                                                send "\n"
                                                                            }
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    expect eof
EOF
}
openssl genrsa -des3 -passout pass:x -out dashboard.pass.key 2048
openssl rsa -passin pass:x -in dashboard.pass.key -out dashboard.key
rm -f dashboard.pass.key
yum install expect -y
auto_openssl_req
openssl x509 -req -sha256 -days 365 -in dashboard.csr -signkey dashboard.key -out dashboard.crt
