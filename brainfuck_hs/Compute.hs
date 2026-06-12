module Compute where
import System.IO

inc :: [Int] -> Int -> [Int]
inc tab ind = mappend (take ind tab) ((mod (succ $ tab!!ind) 256):(drop (ind+1) tab))

dec :: [Int] -> Int -> [Int]
dec tab ind = mappend (take ind tab) ((mod (pred $ tab!!ind) 256):(drop (ind+1) tab))

getInput :: [Int] -> Int -> IO [Int]
getInput tab ind = do
        c <- getChar
        return $ mappend (take ind tab) $ (fromEnum c):(drop (ind+1) tab)

printCell :: [Int] -> Int -> IO ()
printCell tab ind = putChar $ toEnum (tab!!ind)

checkBracket :: String -> Int -> Int
checkBracket _ (-1) = (-1)
checkBracket [] n = n
checkBracket ('[':str) n = checkBracket str (n+1)
checkBracket (']':_) 0 = (-1)
checkBracket (']':str) n = checkBracket str (n-1)
checkBracket str n = checkBracket (tail str) n

findMatching :: String -> Int -> Int
findMatching ('[':str) n = (findMatching str (n+1))+1
findMatching (']':_) 0 = 0
findMatching (']':str) n = (findMatching str (n-1))+1
findMatching str n = (findMatching (tail str) n)+1

executeLoop :: String -> Int -> [Int] -> Int -> IO (Either String ([Int],Int))
executeLoop str pos tab ind
    | pos == (length str) = case tab!!ind of
        0 -> return $ Right (tab, ind)
        _ -> executeLoop str 0 tab ind
    | (str!!pos) == '+' = executeLoop str (pos+1) (inc tab ind) ind
    | (str!!pos) == '-' = executeLoop str (pos+1) (dec tab ind) ind
    | (str!!pos) == '<' && (ind == 0) = return $ Left "error: index cannot be lower than 0"
    | (str!!pos) == '<' = executeLoop str (pos+1) tab (ind-1)
    | (str!!pos) == '>' && (ind == 30000) = return $ Left "error: index cannot be greater than 30000"
    | (str!!pos) == '>' = executeLoop str (pos+1) tab (ind+1)
    | (str!!pos) == ',' = do
        input <- getInput tab ind
        executeLoop str (pos+1) input ind
    | (str!!pos) == '.' = printCell tab ind >> executeLoop str (pos+1) tab ind
    | (str!!pos) == '[' = let substr = drop (pos+1) str
                              mb = findMatching substr 0
        in case tab!!ind of
            0 -> executeLoop str (pos+mb+1) tab ind
            _ -> do
                res <- executeLoop (take mb substr) 0 tab ind
                case res of
                    Left e -> return $ Left e
                    Right (t,i) -> executeLoop str (pos+mb+1) t i
    | otherwise = executeLoop str (pos+1) tab ind

execute :: String -> [Int] -> Int -> IO (Either String ())
execute [] _ _ = return $ Right ()
execute ('+':str) tab ind = execute str (inc tab ind) ind
execute ('-':str) tab ind = execute str (dec tab ind) ind
execute ('<':_) _ 0 = return $ Left "error: index cannot be lower than 0"
execute ('<':str) tab ind = execute str tab (ind-1)
execute ('>':_) _ 29999 = return $ Left "error: index must be lower than 30000"
execute ('>':str) tab ind = execute str tab (ind+1)
execute (',':str) tab ind = do
    input <- getInput tab ind
    execute str input ind
execute ('.':str) tab ind = printCell tab ind >> execute str tab ind
execute ('[':str) tab ind = let mb = findMatching str 0
        in case tab!!ind of
            0 -> execute (drop (mb+1) str) tab ind
            _ -> do
                res <- executeLoop (take mb str) 0 tab ind
                case res of
                    Left e -> return $ Left e
                    Right (t,i) -> execute (drop (mb+1) str) t i
execute (_:str) tab ind = execute str tab ind

fillTab :: Int -> [Int]
fillTab 30000 = []
fillTab len = 0:(fillTab (len+1))

compute :: String -> IO Int
compute [] = return 0
compute str = case checkBracket str 0 of
    0 -> do
        res <- execute str (fillTab 0) 0
        case res of
            Left e -> hPutStrLn stderr (show e) >> return 1
            Right _ -> return 0
    _ -> hPutStrLn stderr "error: mismatch bracket" >> return 1
