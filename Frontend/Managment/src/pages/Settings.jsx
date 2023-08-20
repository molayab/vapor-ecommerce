import { Button, Card, Col, Divider, Flex, Grid, List, ListItem, Metric, Select, SelectItem, Subtitle, TextInput } from "@tremor/react";
import ContainerCard from "../components/ContainerCard";
import SideMenu from "../components/SideMenu";
import SubHeader from "../components/SubHeader";
import { CalculatorIcon, ClockIcon, PlusIcon, SaveIcon } from "@heroicons/react/solid";
import { useEffect, useState } from "react";
import { API_URL, getAllFeatureFlags } from "../App";

function Settings() {
    const [settings, setSettings] = useState({
        siteName: 'Vapor Commerce',
        siteDescription: 'Vapor Commerce es una plataforma de comercio electronico que permite a los usuarios crear tiendas en linea de manera rapida y sencilla.',
        siteUrl: 'https://vaporcommerce.com',
        analyticsProvider: {
            pkKey: '',
            apiKey: '',
            host: '',
            projectId: ''
        }
    })

    const [featureFlags, setFeatureFlags] = useState([])
    const fetchAllFeatureFlags = async () => {
        const response = await fetch(API_URL + '/settings/flags', {
            method: 'GET',
            headers: { 'Content-Type': 'application/json' }
        })

        const data = await response.json()
        console.log(data)

        if (data.results) {
            setFeatureFlags(data.results)
        }
    }

    const fetchSettings = async () => {
        const response = await fetch(API_URL + '/settings', {
            method: 'GET',
            headers: { 'Content-Type': 'application/json' }
        })

        const data = await response.json()
        console.log(data)

        if (data) {
            setSettings(data)
        }
    }

    const saveSettings = async () => {
        const response = await fetch(API_URL + '/settings', {
            method: 'PATCH',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(settings)
        })

        const data = await response.json()
        console.log(data)
    }

    const toggleFeatureFlag = async (flag) => {
        localStorage.removeItem('featureFlags')

        const response = await fetch(API_URL + '/settings/flags/' + flag.key, {
            method: 'PATCH',
            headers: { 'Content-Type': 'application/json' }
        })

        const data = await response.json()
        console.log(data)

        if (data.results) {
            setFeatureFlags(data.results)
        }
    }

    useEffect(() => {
        fetchSettings()
        fetchAllFeatureFlags()
    }, [])

  return (
    <SideMenu>
        <ContainerCard
            title="Generales" 
            subtitle="Ajustes"
            action={
                <Button onClick={(e) => saveSettings() } icon={SaveIcon}>Guardar</Button>
            }>

            <TextInput value={ settings.siteName } onChange={ (e) => setSettings({ ...settings, siteName: e.target.value }) } className="my-2" placeholder="Nombre de la tienda" />
            <TextInput value={ settings.siteDescription } onChange={ (e) => setSettings({ ...settings, siteDescription: e.target.value }) } className="my-2" placeholder="Descripcion de la tienda" />
            <TextInput value={ settings.siteUrl } onChange={ (e) => setSettings({ ...settings, siteUrl: e.target.value }) } className="my-2" placeholder="URL de la tienda" />
        </ContainerCard>

        <Card className="mt-2">
            <Subtitle>Los costos operativos son costos que se incurren en el proceso de mantenimiento y administración de una empresa. Estos pueden ser costos fijos o variables que se incurren en el proceso de producción o venta de bienes y servicios. Algunos ejemplos de costos operativos son: alquiler, salarios, seguros, servicios públicos, etc.</Subtitle>
            <Flex>
                <Metric className="mt-1">Costos Operativos</Metric>
                <div className="flex gap-2 mt-4">
                    <Button icon={PlusIcon}>Agregar</Button>
                    <Button icon={ClockIcon} variant="secondary">Agregar gasto periodico</Button>
                </div>
            </Flex>
        </Card>

        <Grid numItems={2} className="mt-2 gap-4">
            <Card>
                <Metric>Feature Flags</Metric>
                <Subtitle className="mt-2">Los feature flags son una técnica de desarrollo de software que consiste en desacoplar el despliegue de código de la liberación de funcionalidades. Esto permite a los desarrolladores desplegar código en producción que no está terminado y que no es visible para los usuarios finales.</Subtitle>
            
                <List className="mt-2">
                    <ListItem>
                        <span className=""><strong>Nombre</strong></span>
                        <span className=""><strong>Estado</strong></span>
                    </ListItem>
                    {featureFlags.map((flag) => (
                        <ListItem>
                            <span className="">{flag.key}</span>
                            <span className="">
                                <Button 
                                    onClick={ (e) => toggleFeatureFlag(flag) }
                                    variant={flag.active ? 'primary' : 'secondary'}>{flag.active ? 'ON' : 'OFF'}</Button>
                            </span>
                        </ListItem>
                    ))}
                </List>
            </Card>

            <Card>
                <Metric>PostHog: Configuration</Metric>
                <Subtitle className="mt-2">La aplicación PostHog es una herramienta de analítica de código abierto que permite a los equipos de ingeniería y producto rastrear, analizar y comprender el comportamiento de los usuarios en sus aplicaciones y sitios web. Vapor Commerce utiliza PostHog para analizar el comportamiento de los usuarios en la plataforma.</Subtitle>

                <TextInput value={ settings.analyticsProvider.projectId } onChange={ (e) => setSettings({ ...settings, analyticsProvider: { ...settings.analyticsProvider, projectId: e.target.value } }) } className="my-2" placeholder="PostHog Project ID" />
                <TextInput value={ settings.analyticsProvider.pkKey } onChange={ (e) => setSettings({ ...settings, analyticsProvider: { ...settings.analyticsProvider, pkKey: e.target.value } }) } className="my-2" placeholder="PostHog Public Key" />
                <TextInput type="password" onClick={ (e) => {
                    if (e.target.type === 'password') {
                        e.target.type = 'text'
                    } else {
                        e.target.type = 'password'
                    }
                }} value={ settings.analyticsProvider.apiKey } onChange={ (e) => setSettings({ ...settings, analyticsProvider: { ...settings.analyticsProvider, apiKey: e.target.value } }) } className="my-2" placeholder="PostHog API Key" />
                <Divider />
                <Button 
                    variant="secondary"
                    onClick={ (e) => window.open('https://app.posthog.com', '_blank')}
                    className="my-2 w-full">Ver Analiticas</Button>
                <Button className="my-2 w-full">Guardar configuracion</Button>
                <Divider />
                <Button
                    onClick={ (e) => window.open('https://app.posthog.com/feature_flags', '_blank')}
                    className="my-2 w-full" color="amber" variant="secondary">Crear flags requeridos</Button>

            </Card>
        </Grid>
    </SideMenu>
  );
}

export default Settings