#!/bin/bash
echo ">>> Deleting demo cluster..."
kind delete cluster --name k136-demo 2>/dev/null && echo "Deleted k136-demo" || echo "k136-demo not found"
echo ">>> Done!"
