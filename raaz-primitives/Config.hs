{-|

This module does the configuration. It has logic to detect various
parameters. Nevertheless it also allows for manual configurations of
each and every parameters. For the manual options you can edit the top
section of this module.


-}
module Config
       ( configure
       , genConfigFile
       ) where

import Control.Monad
import System.FilePath

import Raaz.Config.Monad
import Raaz.Config.FFI
import Config.Cache(cache)
import Config.Page(pageSize)


------------------ Defaults ---------------------------------------
--
-- These are the options that we use as defaults when autoconf is not
-- being used. If you want manual configurations edit this and
-- configure with --no-autoconf
--

-- | Size of the L1 cache.
l1CacheSize :: Int
l1CacheSize = 0

-- | Size of the L2 cache.
l2CacheSize :: Int
l2CacheSize = 0

-- | Size of a virtual memory page.
defaultPageSize :: Int
defaultPageSize = 4096

-- | Functions that the C environment provides. Uncomments the ones
-- that are required. Currently all functions are disabled but you can
-- include in this list a subset of what is available in
-- functionsToCheck
availableFunctions :: [String]
availableFunctions =  []


-- | Functions whose existance is checked by the auto configuration.
functionsToCheck = [ "htole32"
                   , "htole64"
                   , "htobe32"
                   , "htobe64"
                   , "mlock"
                   , "mlockall"
                   , "memalign"
                   ]



-- | The main configuration action. This justs packages the actual
-- configuration.
configure :: Bool -> ConfigM ()
configure auto = do
  comment "Auto generated stuff (do not edit)"
  wrapHeaderFile "__RAAZ_PRIMITIVES_CONF_H__" $ actualConfig auto

-- | Here is where the actual configuration happens.
actualConfig :: Bool -> ConfigM ()
actualConfig auto = do
  if auto then comment "System parameters guessed by Config.hs"
    else comment "System parameters set by manual configuration"

  section "Cache parameters"     $ configureCache auto
  section "Page Size parameters" $ configurePageSize auto

  section "Mark all FFI functions unavailable" $
    forM_ functionsToCheck dontHave

  section "Selectively enable the available ones." $
    if auto then forM_ functionsToCheck checkFFIFunction
      else forM_ availableFunctions have

section :: String -> ConfigM () -> ConfigM ()
section com action = do comment com
                        action
                        comment $ "End of " ++ com
                        newline

-- | Configuring the L1 and L2 cache values.
configureCache auto = do
  (l1,l2) <- if auto then cache else return (l1CacheSize,l2CacheSize)
  define "RAAZ_L1_CACHE" $ show l1
  define "RAAZ_L2_CACHE" $ show l2


-- | Configuring Page Size.
configurePageSize auto = do
  p <- if auto then pageSize else return defaultPageSize
  define "RAAZ_PAGE_SIZE" $ show p


checkFFIFunction :: String -> ConfigM ()
checkFFIFunction funcName = do
  chk <- ffiTest ffiPath
  when chk $ have funcName
  where ffiPath = "Config" </> "ffi" </> funcName


have :: String -> ConfigM ()
have func = define' $ "RAAZ_HAVE_" ++ func

dontHave :: String -> ConfigM ()
dontHave func = undef $ "RAAZ_HAVE_" ++ func
