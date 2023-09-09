import React, { useState } from 'react'
import { Card, Button, Grid, TextInput } from '@tremor/react'

export default function Keypad ({ onNumberPadClick }) {
  const _onNumberPadClick = (value) => {
    setCode(prev => {
      if (value === 'DEL') {
        return prev.slice(0, -1)
      }
      if (value === 'ENTER') {
        return ''
      }
      return prev + value
    })

    onNumberPadClick(value)
  }

  const [code, setCode] = useState('')

  return (
    <Card>
      <TextInput value={code} placeholder='SKU' readOnly className='mb-4' />
      <Grid numItems={3} className='gap-2'>
        <Button variant='secondary' onClick={() => _onNumberPadClick(1)} className='h-14'>
          1
        </Button>
        <Button variant='secondary' onClick={() => _onNumberPadClick(2)} className='h-14'>
          2
        </Button>
        <Button variant='secondary' onClick={() => _onNumberPadClick(3)} className='h-14'>
          3
        </Button>
        <Button variant='secondary' onClick={() => _onNumberPadClick(4)} className='h-14'>
          4
        </Button>
        <Button variant='secondary' onClick={() => _onNumberPadClick(5)} className='h-14'>
          5
        </Button>
        <Button variant='secondary' onClick={() => _onNumberPadClick(6)} className='h-14'>
          6
        </Button>
        <Button variant='secondary' onClick={() => _onNumberPadClick(7)} className='h-14'>
          7
        </Button>
        <Button variant='secondary' onClick={() => _onNumberPadClick(8)} className='h-14'>
          8
        </Button>
        <Button variant='secondary' onClick={() => _onNumberPadClick(9)} className='h-14'>
          9
        </Button>
        <Button variant='secondary' onClick={() => _onNumberPadClick(0)} className='h-14'>
          0
        </Button>
        <Button onClick={() => _onNumberPadClick('ENTER')} className='h-14'>
          <b>ENTER</b>
        </Button>
        <Button onClick={() => _onNumberPadClick('DEL')} className='h-14'>
          <b>DEL</b>
        </Button>
      </Grid>
    </Card>
  )
}
