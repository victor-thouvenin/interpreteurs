module Compute where
import System.IO

stackErrorMsg :: Int -> IO (Either String ())
stackErrorMsg pos = return $ Left $ mappend "Stack underflow at line " $ show (pos+1)

execute :: [Int] -> Int -> [Int] -> IO (Either String ())
execute list pos stack
    | pos >= (length list) = return $ Right ()
    -- inp
    | (list!!pos) == 9 = do
        c <- getChar
        execute list (pos+1) $ ((:stack).fromEnum) c
    -- add
    | (list!!pos) == 10 = if (length stack)<2
        then stackErrorMsg pos
        else execute list (pos+1) $ ((stack!!0)+(stack!!1)):(drop 2 stack)
    -- sub
    | (list!!pos) == 11 = if (length stack)<2
        then stackErrorMsg pos
        else execute list (pos+1) $ ((stack!!1)-(stack!!0)):(drop 2 stack)
    -- dup
    | (list!!pos) == 12 = execute list (pos+1) $ (stack!!0):stack
    -- cond
    | (list!!pos) == 13 = case stack of
        [] -> stackErrorMsg pos
        (0:stk) -> if elem (list!!(pos+1)) [14, 25]
            then execute list (pos+3) stk
            else execute list (pos+2) stk
        (_:stk) -> execute list (pos+1) stk
    -- gotou
    | (list!!pos) == 14 = execute list (list!!(pos+1)) stack
    -- outn
    | (list!!pos) == 15 = case stack of
        [] -> stackErrorMsg pos
        (n:stk) -> (putStr.show) n >> execute list (pos+1) stk
    -- outa
    | (list!!pos) == 16 = case stack of
        [] -> stackErrorMsg pos
        (n:stk) -> (putChar.toEnum) n >> execute list (pos+1) stk
    -- rol
    | (list!!pos) == 17 = case stack of
        [] -> stackErrorMsg pos
        (n:stk) -> execute list (pos+1) $ mappend stk [n]
    -- swap
    | (list!!pos) == 18 = if (length stack)<2
        then stackErrorMsg pos
        else execute list (pos+1) $ (stack!!1):(stack!!0):(drop 2 stack)
    -- mul
    | (list!!pos) == 20 = if (length stack)<2
        then stackErrorMsg pos
        else execute list (pos+1) $ ((stack!!0)*(stack!!1)):(drop 2 stack)
    -- div
    | (list!!pos) == 21 = if (length stack)<2
        then stackErrorMsg pos
        else execute list (pos+1) $ ((stack!!1)`div`(stack!!0)):(drop 2 stack)
    -- pop
    | (list!!pos) == 23 = case stack of
        [] -> stackErrorMsg pos
        (_:stk) -> execute list (pos+1) stk
    -- gotos
    | (list!!pos) == 24 = case stack of
        [] -> stackErrorMsg pos
        (n:stk) -> execute list (n+1) stk
    -- push
    | (list!!pos) == 25 = execute list (pos+2) ((list!!(pos+1)):stack)
    -- ror
    | (list!!pos) == 27 = case stack of
        [] -> stackErrorMsg pos
        _ -> execute list (pos+1) $ (last stack):(init stack)
    | otherwise = execute list (pos+1) stack

compute :: String -> IO Int
compute [] = return 0
compute str = do
    res <- execute (map length $ lines str) 0 []
    case res of
        Left e -> hPutStrLn stderr (show e) >> return 1
        Right _ -> return 0
