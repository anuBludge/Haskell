module Var1 where
import           Control.Monad.State
type M a = StateT Integer (Either String) a

throw :: String -> M a
throw = lift . Left

showE :: Show a => Either String a -> String
showE (Left s)  = "Error: " ++ s
showE (Right a) = "Success: " ++ show a

showM :: Show a => M a -> String
showM ma = showE (fst <$> eas) ++
  case eas of
    Right (_,s) -> "\n" ++ "Count: " ++ show s
    _   -> ""
  where eas = runStateT ma 0

type Name = String

data Term = Var Name
          | Con Integer
          | Term :+: Term
          | Lam Name Term
          | App Term Term
  deriving (Show)

pgm :: Term
pgm = App
  (Lam "y"
    (App
      (App
        (Lam "f"
          (Lam "y"
            (App (Var "f") (Var "y"))
          )
        )
        (Lam "x"
          (Var "x" :+: Var "y")
        )
      )
      (Con 3)
    )
  )
  (Con 4)


data Value = Num Integer
           | Fun (Value -> M Value)

type Environment = [(Name, Value)]

instance Show Value where
  show (Num x) = show x
  show (Fun _) = "<function>"

interp :: Term -> Environment -> M Value
interp (Var x) env = lookupM x env
interp (Con i) _ = return $ Num i
interp (t1 :+: t2) env = do
  v1 <- interp t1 env
  v2 <- interp t2 env
  add v1 v2
interp (Lam x e) env = return $ Fun $ \ v -> interp e ((x,v):env)
interp (App t1 t2) env = do
  f <- interp t1 env
  v <- interp t2 env
  apply f v

lookupM :: Name -> Environment -> M Value
lookupM x env = case [v | (y,v) <- env , x == y] of
  (v:_) -> return v
  _     -> throw ("unbound variable " ++ x)

add :: Value -> Value -> M Value
add (Num i) (Num j) = return $ Num $ i + j
add v1 v2             = throw ("should be numbers: " ++ show v1 ++ ", " ++ show v2)

apply :: Value -> Value -> M Value
apply (Fun k) v = k v
apply v _       = throw ("should be function: " ++ show v)

test :: Term -> String
test t = showM $ interp t []
