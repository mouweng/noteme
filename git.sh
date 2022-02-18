if [ ! $1 ]
then
  echo "🔖 Missing commit message..."
  exit;
fi

git add .
git status
sleep 1s
git commit -m "$1"
sleep 1s
git push
echo "✔️ success"