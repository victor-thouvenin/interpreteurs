module Read where
import System.IO
import Control.Exception
import Compute

readArg :: String -> IO String
readArg arg = do
    file <- try (readFile arg)::IO(Either SomeException String)
    case file of
        Left e -> throw e
        Right f -> return f

readArgs :: [String] -> IO Int
readArgs [] = hPutStrLn stderr "input file missing" >> return 1
readArgs (arg:_) = do
        file <- try(readArg arg)::IO(Either SomeException String)
        case file of
            Left e -> hPutStrLn stderr (show e) >> return 1
            Right f -> compute f
