import React from 'react';
import { Card, Button, Grid } from '@tremor/react';

export default function Keypad({ onNumberPadClick }) {
    return (
        <Card>
            <Grid numItems={3} className="gap-2">
                <Button onClick={ () => onNumberPadClick(1) }>
                    1
                </Button>
                <Button onClick={ () => onNumberPadClick(2) }>
                    2
                </Button>
                <Button onClick={ () => onNumberPadClick(3) }>
                    3
                </Button>
                <Button onClick={ () => onNumberPadClick(4) }>
                    4
                </Button>
                <Button onClick={ () => onNumberPadClick(5) }>
                    5
                </Button>
                <Button onClick={ () => onNumberPadClick(6) }>
                    6
                </Button>
                <Button onClick={ () => onNumberPadClick(7) }>
                    7
                </Button>
                <Button onClick={ () => onNumberPadClick(8) }>
                    8
                </Button>
                <Button onClick={ () => onNumberPadClick(9) }>
                    9
                </Button>
                <Button onClick={ () => onNumberPadClick(0) }>
                    0
                </Button>
                <Button onClick={ () => onNumberPadClick('ENTER') }>
                    ENTER
                </Button>
                <Button onClick={ () => onNumberPadClick('DEL') }>
                    DEL
                </Button>
            </Grid>
        </Card>
    )
}