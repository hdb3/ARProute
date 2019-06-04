{-# LANGUAGE OverloadedStrings #-}
module Main where
import System.IO(stderr, hPutStrLn)
import System.Process
import System.Environment(getArgs)
import System.Exit
import VirtXML
import LibvirtIP
import Notify

main :: IO()
main = do
    args <- getArgs
    if 1 /= length args then
        die "please ask just one question!"
    else do
        xml <- readProcess "virsh" ["dumpxml" , head args] ""
        let mac = getNetworkInterfaceMAC xml
        reportIP mac
    where
    reportIP m = do
        recs <- mac2AddressRecords m
        if 1 == length recs then
            print (ipAddress $ head recs)
        else do
            hPutStrLn stderr "waiting on virbr0.status"
            watch <- setWatchModify "/var/lib/libvirt/dnsmasq/virbr0.status"
            flag <- getWatch watch 20
            if flag then reportIP m
            else
                die "timed out waiting for an IP address"
